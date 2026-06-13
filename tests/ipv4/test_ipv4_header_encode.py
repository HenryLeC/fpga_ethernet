from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def test_ipv4_header_encode_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "ipv4" / "header" / "ipv4_header_encode.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="ipv4_header_encode",
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
        hdl_toplevel="ipv4_header_encode",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/ipv4_header_encode.fst"],
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

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    header = [0x00450008, 0x34121400, 0x11400000, 0x0101A35C, 0x000A0101, 0x00000100]

    dut.packet_length.value = 20
    dut.identification.value = 0x1234
    dut.protocol.value = 17
    dut.source_address.value = 0x01010101
    dut.destination_address.value = 0x0A000001
    dut.data_valid.value = 1

    dut.m_axis_tready.value = 0
    for _ in range(5):
        await FallingEdge(dut.i_clk)
    dut.m_axis_tready.value = 1

    for idx, dword in enumerate(header):
        assert dut.m_axis_tdata.value == dword
        if idx == len(header) - 1:
            assert dut.m_axis_tlast.value

        await FallingEdge(dut.i_clk)

    dut.m_axis_tready.value = 0
    dut.data_valid.value = 0
    for _ in range(5):
        await FallingEdge(dut.i_clk)
    dut.data_valid.value = 1
    for _ in range(5):
        await FallingEdge(dut.i_clk)
    dut.m_axis_tready.value = 1

    for idx, dword in enumerate(header):
        assert dut.m_axis_tdata.value == dword
        if idx == len(header) - 1:
            assert dut.m_axis_tlast.value

        await FallingEdge(dut.i_clk)
