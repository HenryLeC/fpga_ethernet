from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer
import random


def test_block_lock_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "rx" / "block_lock_sm.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="block_lock_sm",
        always=True,
        waves=True,
        build_args=["--trace-fst", "--trace-structs", f"-I{proj_path / "src"}"],
    )
    runner.test(
        hdl_toplevel="block_lock_sm",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../block_lock_sm.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk_rx.value = 0
        await Timer(1, unit="ns")
        dut.clk_rx.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_decoder(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.rst_a.value = 1

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk_rx)  # wait for falling edge/"negedge"
    dut.rst_a.value = 0

    location = 60

    for i in range(10000):
        dut.rx_header.value = 1 if location == 0 else random.randint(0, 3)
        await FallingEdge(dut.clk_rx)
        if dut.gearbox_slip.value:
            location -= 1

    assert location == 0
