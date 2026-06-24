from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import RisingEdge, Timer


def test_scrambler_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "blog_examples" / "scrambler.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="scrambler",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
        ],
    )
    runner.test(
        hdl_toplevel="scrambler",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/blog_examples/scrambler.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_scrambler(dut):

    cocotb.start_soon(generate_clock(dut))
    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    # These come from https://grouper.ieee.org/groups/802/3/ae/public/jul00/walker_1_0700.pdf
    data_in = 0x000000000000001E
    data_correct = 0x7BFFF0800000001E

    for i in range(64):
        dut.i_arst.value = 0
        dut.bit_in.value = (data_in >> i) & 1
        await RisingEdge(dut.i_clk)
        assert dut.bit_out.value == (data_correct >> i) & 1
