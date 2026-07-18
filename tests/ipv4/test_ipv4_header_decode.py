from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer

from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus


def test_ipv4_header_decode_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "ipv4" / "header" / "ipv4_header_decode.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="ipv4_header_decode",
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
        hdl_toplevel="ipv4_header_decode",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/ipv4_header_decode.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


def ones_complement_sum(a, b, bits=32):
    """Computes the one's complement sum of two integers."""
    total = a + b
    # Fold the carry bits back into the lower bits
    max_val = (1 << bits) - 1
    while total > max_val:
        total = (total & max_val) + (total >> bits)
    return total


@cocotb.test()
async def test_ipv4_header_ihl5(dut):
    await header_test(
        dut,
        [
            0x45,
            0x00,
            0x00,
            0x14,
            0x12,
            0x34,
            0x00,
            0x00,
            0x40,
            0x11,
            0x00,
            0x00,
            0x01,
            0x01,
            0x01,
            0x01,
            0x0A,
            0x00,
            0x00,
            0x01,
        ],
    )


@cocotb.test()
async def test_ipv4_header_ihl6(dut):
    await header_test(
        dut,
        [
            0x46,
            0x00,
            0x00,
            0x14,
            0x12,
            0x34,
            0x00,
            0x00,
            0x40,
            0x11,
            0x00,
            0x00,
            0x01,
            0x01,
            0x01,
            0x01,
            0x0A,
            0x00,
            0x00,
            0x01,
            0x00,
            0x00,
            0x00,
            0x00,
        ],
    )


async def header_test(dut, header):
    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    source = AxiStreamSource(
        AxiStreamBus(dut, "s_axis"), dut.i_clk, dut.i_arst, byte_lanes=8
    )

    assert header[10] | header[11] == 0, "Header checksum must be 0 for calculation"

    checksum = 0
    for idx in range(0, len(header), 2):
        word = header[idx] | (header[idx + 1] << 8)

        checksum = ones_complement_sum(checksum, word)

    checksum = (checksum & 0xFFFF) ^ 0xFFFF

    header[10] = checksum & 0xFF
    header[11] = checksum >> 8

    checksum = 0
    for idx in range(0, len(header), 2):
        word = header[idx] | (header[idx + 1] << 8)

        checksum = ones_complement_sum(checksum, word)

    assert checksum & 0xFFFF == 0xFFFF, f"{checksum:08x} != FFFFFFFF"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    frame = AxiStreamFrame(tdata=header, tx_complete=Event())
    await source.send(frame)
    await frame.tx_complete.wait()

    await dut.i_clk.rising_edge

    assert dut.s_axis_tlast.value
    assert dut.header_tkeep.value == 1 if len(header) % 8 else 3

    if not dut.decode_done.value:
        await RisingEdge(dut.decode_done)

    assert dut.packet_length.value == 20
    assert dut.identification.value == 0x1234
    assert dut.protocol.value == 17
    assert dut.source_address.value == 0x01010101
    assert dut.destination_address.value == 0x0A000001
