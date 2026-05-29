from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import RisingEdge, Timer


def test_frame_encoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "mac" / "tx" / "frame_encoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="frame_encoder",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            f"-I{proj_path / "src"}",
            f"-I{proj_path / "src" / "include"}",
        ],
    )
    runner.test(
        hdl_toplevel="frame_encoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../frame_encoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_frame_encoder(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    packet = [
        0x01000608,
        0x04060008,
        0x01C00100,
        0xCB35F222,
        0xCD01000A,
        0x00000000,
        0x01010000,
        0x00000101,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
    ]

    i = 0
    dut.i_clientdata.value = packet[i]
    dut.i_clientdata_valid.value = 0xF

    await RisingEdge(dut.i_clk)

    cnt = 0
    while cnt < 100:
        if i == len(packet) - 1:
            break
        if dut.o_ready.value:
            i += 1
            dut.i_clientdata.value = packet[i]
            dut.i_clientdata_valid.value = 0xF
            dut.i_last.value = i == len(packet) - 1
        await RisingEdge(dut.i_clk)
        cnt += 1

    assert i == len(packet) - 1

    while dut.TXD.value != 0x07070707:
        await RisingEdge(dut.i_clk)
