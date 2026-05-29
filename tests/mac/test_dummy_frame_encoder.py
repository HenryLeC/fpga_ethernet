from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import RisingEdge, Timer


def test_dummy_frame_encoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "mac" / "tx" / "dummy_frame_encoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="dummy_frame_encoder",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            f"-I{proj_path / "src"}",
            f"-I{proj_path / "src" / "include"}",
            f"-I{proj_path / "src" / "mac"}",
            f"-I{proj_path / "src" / "mac" / "tx"}",
        ],
    )
    runner.test(
        hdl_toplevel="dummy_frame_encoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../dummy_frame_encoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_dummy_frame_encoder(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    while dut.TXD.value == 0x07070707:
        await RisingEdge(dut.i_clk)

    while dut.TXD.value != 0x07070707:
        await RisingEdge(dut.i_clk)
