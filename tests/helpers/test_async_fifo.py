from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Combine, FallingEdge, Timer


def test_async_fifo_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "helpers" / "async_fifo.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="async_fifo",
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
        hdl_toplevel="async_fifo",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/async_fifo.fst"],
    )


async def generate_read_clk(dut):
    dut.i_rclk.value = 1
    await Timer(5, unit="ns")
    while True:
        dut.i_rclk.value = 0
        await Timer(5, unit="ns")
        dut.i_rclk.value = 1
        await Timer(5, unit="ns")


async def generate_write_clk(dut):
    while True:
        dut.i_wclk.value = 0
        await Timer(5, unit="ns")
        dut.i_wclk.value = 1
        await Timer(5, unit="ns")


async def write_side(dut):
    await FallingEdge(dut.i_wclk)

    dut.i_wrst.value = 1

    await FallingEdge(dut.i_wclk)

    dut.i_wrst.value = 0
    dut.i_wr.value = 1
    i = 0
    while dut.o_wfull.value == 0:
        dut.i_wdata.value = i
        await FallingEdge(dut.i_wclk)
        i += 1
    await FallingEdge(dut.i_wclk)
    assert dut.o_wfull.value == 1
    assert i == 16  # we write in 8 while reading and then write another 16


async def read_side(dut):
    await FallingEdge(dut.o_rempty)

    await FallingEdge(dut.i_rclk)
    dut.i_rd.value = 1
    for i in range(8):
        assert dut.o_rdata.value == i
        await FallingEdge(dut.i_rclk)
    dut.i_rd.value = 0


@cocotb.test()
async def test_async_fifo(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_read_clk(dut))  # run the clock "in the background"
    cocotb.start_soon(generate_write_clk(dut))  # run the clock "in the background"

    await Combine(
        cocotb.start_soon(write_side(dut)),
        cocotb.start_soon(read_side(dut)),
    )
