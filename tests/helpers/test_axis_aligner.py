from pathlib import Path
from typing import Generator

import cocotb
import random
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer, Event


def test_axis_aligner_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "helpers" / "axis_aligner.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="axis_aligner",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            "-F",
            f"{proj_path / "verilator.vc"}",
        ],
    )
    runner.test(
        hdl_toplevel="axis_aligner",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/axis_aligner.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


async def verify_receive_bytes(dut, count, event: Event):
    print("started")
    counted = 0
    while True:
        await dut.i_clk.rising_edge
        if dut.m_axis_tvalid.value and dut.m_axis_tready.value:
            assert int(dut.m_axis_tkeep.value) & 1
            for i in range(8):
                if not (int(dut.m_axis_tkeep.value) >> i) & 1:
                    assert dut.m_axis_tlast.value
                    assert counted == count
                    assert not int(dut.m_axis_tkeep.value) >> i
                    break

                assert (int(dut.m_axis_tdata.value) >> (i * 8)) & 0xFF == counted
                print(counted)
                counted += 1

            if dut.m_axis_tlast.value:
                assert counted == count
                break

    event.set()


async def master_ready_toggle(dut):
    while True:
        await dut.i_clk.rising_edge
        # dut.m_axis_tready.value = random.randint(0, 1)
        dut.m_axis_tready.value = True


def valid_gen():
    while True:
        yield True


async def axis_send(
    dut, bytes, start_offset, valid_generator: Generator[bool, None, None]
):
    index = 8 - start_offset
    valid = False
    while not (valid and dut.s_axis_tready.value):
        valid = next(valid_generator, True)
        dut.s_axis_tdata.value = list_to_value(([0] * start_offset) + bytes[:index])
        dut.s_axis_tkeep.value = offset_to_keep(start_offset)
        dut.s_axis_tlast.value = index > len(bytes)
        dut.s_axis_tvalid.value = valid

        if not (valid and dut.s_axis_tready.value):
            await dut.i_clk.rising_edge

    while True:
        await dut.i_clk.rising_edge

        if dut.s_axis_tvalid.value and dut.s_axis_tready.value:
            if index >= len(bytes):
                break
            index += 8

        if index <= len(bytes):
            dut.s_axis_tdata.value = list_to_value(bytes[index - 8 : index])
            dut.s_axis_tkeep.value = 0xFF
            dut.s_axis_tlast.value = index == len(bytes)
            dut.s_axis_tvalid.value = next(valid_generator)
        else:
            dut.s_axis_tdata.value = list_to_value(bytes[index - 8 :])
            dut.s_axis_tkeep.value = 0xFF >> (8 - (len(bytes[index - 8 :])))
            dut.s_axis_tlast.value = True
            dut.s_axis_tvalid.value = next(valid_generator)

    dut.s_axis_tvalid.value = False


@cocotb.test()
async def test_axis_aligner(dut):

    random.seed(0xFEED)

    cocotb.start_soon(generate_clock(dut))
    cocotb.start_soon(master_ready_toggle(dut))

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    byte_values = [i for i in range(0, 256)]
    for _ in range(10):
        print("Batch Start")
        for offset in range(8):
            end_offset = random.randint(0, 7)
            finish_event = Event()
            cocotb.start_soon(
                verify_receive_bytes(
                    dut, 8 + (8 - end_offset) + (8 - offset), finish_event
                )
            )
            await dut.i_clk.rising_edge

            bytes = byte_values[: 8 * 3 - (offset + end_offset)]

            await axis_send(dut, bytes, offset, valid_gen())
            await finish_event.wait()

        await RisingEdge(dut.i_clk)


def list_to_value(items):
    x = 0
    for val in items[::-1]:
        x = (x << 8) | val
    return x


def offset_to_keep(offset):
    return (0xFF << offset) & 0xFF
