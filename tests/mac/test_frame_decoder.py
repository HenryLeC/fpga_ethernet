from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def test_frame_decoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "mac" / "rx" / "frame_decoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="frame_decoder",
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
        hdl_toplevel="frame_decoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/frame_decoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


async def check_packet(dut):
    packet = [
        0x01000608,
        0x04060008,
        0x01C00100,
        0xCB35F222,
        0xCD01000A,
        0x00000000,
        0x01010000,
        0x00000101,
        0x00000000,
        0x00000000,
        0x00000000,
        0x00000000,
    ]

    await RisingEdge(dut.m_axis_tvalid)
    await FallingEdge(dut.i_clk)

    for dword in packet:
        assert dut.m_axis_tdata.value == dword
        assert dut.m_axis_tkeep.value == 0xF
        await FallingEdge(dut.i_clk)


@cocotb.test()
async def test_frame_decoder(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    cocotb.start_soon(check_packet(dut))

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

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

    for cycle in frame:
        dut.i_RXC.value = cycle[0]
        dut.i_RXD.value = cycle[1]

        await RisingEdge(dut.i_clk)

    assert dut.m_axis_tlast.value
    await RisingEdge(dut.i_clk)
    assert not dut.m_axis_tinvalid.value
