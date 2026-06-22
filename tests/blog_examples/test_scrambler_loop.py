from pathlib import Path
import random

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def test_scrambler_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "blog_examples" / "scrambler_loop.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="scrambler_loop",
        always=True,
        waves=True,
        build_args=["--trace-fst", "--trace-structs", f"-I{sources[0].parent}"],
    )
    runner.test(
        hdl_toplevel="scrambler_loop",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/blog_examples/scrambler_loop.fst"],
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
    await RisingEdge(dut.i_clk)

    for _ in range(5):
        data_in = random.randint(0, 2**64 - 1)
        dut.data_in.value = data_in
        await FallingEdge(dut.i_clk)
        assert dut.data_out.value == data_in
        await RisingEdge(dut.i_clk)
