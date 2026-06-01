from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def test_dummy_frame_encoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "mac" / "tx" / "dummy_frame_encoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="dummy_frame_encoder",
        always=True,
        waves=True,
        parameters={"COUNT_BITS": "5"},
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


async def check_frame(dut):
    frame = [
        (1, 0x555555FB),
        (0, 0xD5555555),
        (0, 0xFFFFFFFF),
        (0, 0x01C0FFFF),
        (0, 0xCB35F222),
        (0, 0x01000608),
        (0, 0x04060008),
        (0, 0x01C00100),
        (0, 0xCB35F222),
        (0, 0xCD01000A),
        (0, 0x00000000),
        (0, 0x01010000),
        (0, 0x00000101),
        (0, 0x00000000),
        (0, 0x00000000),
        (0, 0x00000000),
        (0, 0x00000000),
        (0, 0xE5BFB3A8),
        (0xF, 0x070707FD),
    ]

    await FallingEdge(dut.i_clk)
    while dut.TXD.value == 0x07070707:
        await FallingEdge(dut.i_clk)

    for txc, txd in frame:
        assert dut.TXC.value == txc
        assert dut.TXD.value == txd
        await FallingEdge(dut.i_clk)


@cocotb.test()
async def test_dummy_frame_encoder(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"
    cocotb.start_soon(check_frame(dut))

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    while dut.TXD.value == 0x07070707:
        await RisingEdge(dut.i_clk)

    while dut.TXD.value != 0x07070707:
        await RisingEdge(dut.i_clk)

    while dut.TXD.value == 0x07070707:
        await RisingEdge(dut.i_clk)

    while dut.TXD.value != 0x07070707:
        await RisingEdge(dut.i_clk)
