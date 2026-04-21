from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_gearbox_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    print(proj_path / "src" / "gearbox" / "gearbox.sv")
    sources = [proj_path / "src" / "gearbox" / "gearbox.sv"]

    runner = get_runner("verilator")
    runner.build(sources=sources, hdl_toplevel="gearbox", always=True)
    runner.test(hdl_toplevel="gearbox", test_module=__name__)


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_gearbox(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.arst_n.value = 0

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    dut.arst_n.value = 1
    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    cocotb.log.info("led is %s", dut.led.value)
    assert dut.led.value == 0

    await Timer(2**10, unit="ns")
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    cocotb.log.info("led is %s", dut.led.value)
    assert dut.led.value != 0
