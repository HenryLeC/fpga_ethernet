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
            f"-I{proj_path / "src"}",
            f"-I{proj_path / "src" / "include"}",
        ],
    )
    runner.test(
        hdl_toplevel="ipv4_header_decode",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../ipv4_header_decode.fst"],
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
async def test_crc_calc(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    source = AxiStreamSource(
        AxiStreamBus(dut, "s_axis"), dut.i_clk, dut.i_arst, byte_lanes=1
    )

    header = [0x14000054, 0x00003412, 0x00001140, 0x01010101, 0x0100000A]

    assert header[2] >> 16 == 0, "Header checksum must be 0 for calculation"

    checksum = 0
    for dword in header:
        word_1 = dword & 0xFFFF
        word_2 = dword >> 16

        checksum = ones_complement_sum(checksum, word_1)
        checksum = ones_complement_sum(checksum, word_2)

    checksum = (checksum & 0xFFFF) ^ 0xFFFF

    header[2] = header[2] | (checksum << 16)

    checksum = 0
    for dword in header:
        word_1 = dword & 0xFFFF
        word_2 = dword >> 16

        checksum = ones_complement_sum(checksum, word_1)
        checksum = ones_complement_sum(checksum, word_2)
    assert checksum & 0xFFFF == 0xFFFF, f"{checksum:08x} != FFFFFFFF"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    frame = AxiStreamFrame(tdata=header, tx_complete=Event())
    await source.send(frame)
    await frame.tx_complete.wait()

    await RisingEdge(dut.s_axis_tdone)

    assert dut.packet_length.value == 20
    assert dut.identification.value == 0x1234
    assert dut.protocol.value == 17
    assert dut.source_address.value == 0x01010101
    assert dut.destination_address.value == 0x0A000001
