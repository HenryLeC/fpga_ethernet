from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Combine, FallingEdge, RisingEdge, Timer


def test_sync_fifo_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "helpers" / "sync_fifo.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="sync_fifo",
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
        hdl_toplevel="sync_fifo",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/sync_fifo.fst"],
    )


async def generate_clk(dut):
    while True:
        dut.i_clk.value = 0
        await Timer(5, unit="ns")
        dut.i_clk.value = 1
        await Timer(5, unit="ns")


async def write_side(dut):
    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    await FallingEdge(dut.i_clk)
    await FallingEdge(dut.i_clk)
    await FallingEdge(dut.i_clk)

    dut.s_tvalid.value = 1
    for i in range(2**8):
        dut.s_tdata.value = i
        assert dut.s_tready.value
        await FallingEdge(dut.i_clk)
    dut.s_tvalid.value = 0

    assert not dut.s_tready.value


async def read_side(dut):
    await FallingEdge(dut.s_tready)

    await FallingEdge(dut.i_clk)
    assert dut.m_tvalid.value
    dut.m_tready.value = 1
    for i in range(2**8):
        assert dut.m_tdata.value == i
        await FallingEdge(dut.i_clk)
    dut.m_tready.value = 0
    assert not dut.m_tvalid.value


@cocotb.test()
async def test_async_fifo(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clk(dut))  # run the clock
    await Combine(
        cocotb.start_soon(write_side(dut)),
        cocotb.start_soon(read_side(dut)),
    )
