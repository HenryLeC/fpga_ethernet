from pathlib import Path

import cocotb
import glob
import shutil
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, RisingEdge, Timer


def test_crc_calc_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    hex_files = glob.glob("*.hex", root_dir=proj_path / "src" / "mac" / "crc_tables")

    for file in hex_files:
        shutil.copy(
            proj_path / "src" / "mac" / "crc_tables" / file,
            proj_path / "sim_build" / file,
        )

    sources = [proj_path / "src" / "mac" / "crc_calc.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="crc_calc",
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
        hdl_toplevel="crc_calc",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/crc_calc.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_crc_calc(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    packet = [
        0xFFFFFFFF,
        0x01C0FFFF,
        0xCB35F222,
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

    for word in packet:
        dut.i_data.value = word
        dut.i_valid.value = 0xF

        await RisingEdge(dut.i_clk)
    await FallingEdge(dut.i_clk)
    assert dut.o_crc.value == 0xE5BFB3A8
