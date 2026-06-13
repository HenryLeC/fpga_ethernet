from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_pcs_rx_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "rx" / "pcs_rx.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="pcs_rx",
        parameters={"LFSR_INITIAL_STATE": "58'hFFFFFFFFFFFFFFF"},
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
        hdl_toplevel="pcs_rx",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/pcs_rx.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_pcs_rx(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    # These come from https://grouper.ieee.org/groups/802/3/ae/public/jul00/walker_1_0700.pdf
    data_in = [0x0000001E, 0x7BFFF080, 0xAAAD1578, 0x623016AA]
    header_in = [0b01, 0b01]
    RXD_out = [0x07070707, 0x07070707, 0x555555FB, 0xD5555555]
    RXC_out = [0xF, 0xF, 0x1, 0x0]

    for i in range(len(header_in)):
        if i != 0:
            assert dut.RXC.value == RXC_out[(i - 1) * 2]
            assert dut.RXD.value == RXD_out[(i - 1) * 2]
        dut.header_valid.value = 1
        dut.rx_header.value = header_in[i]
        dut.rx_data.value = data_in[2 * i]

        await FallingEdge(dut.clk)
        if i != 0:
            assert dut.RXC.value == RXC_out[(i - 1) * 2 + 1]
            assert dut.RXD.value == RXD_out[(i - 1) * 2 + 1]
        dut.header_valid.value = 0
        dut.rx_header.value = 0
        dut.rx_data.value = data_in[2 * i + 1]

        await FallingEdge(dut.clk)

    assert dut.RXC.value == RXC_out[-2]
    assert dut.RXD.value == RXD_out[-2]

    await FallingEdge(dut.clk)

    assert dut.RXC.value == RXC_out[-1]
    assert dut.RXD.value == RXD_out[-1]
