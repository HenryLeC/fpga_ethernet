from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_scrambler_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "scrambler.sv"]

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
        test_args=["--trace-file", "../scrambler.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_scrambler(dut):

    # These come from walker_1_0700.pdf
    data_in = 0x000000000000001E
    data_correct = 0x7BFFF0800000001E

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.arst_n.value = 0

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    dut.arst_n.value = 1

    data = data_in

    data_out = 0

    for _ in range(64):
        dut.data.value = data & 1
        data = data >> 1
        await FallingEdge(dut.clk)
        data_out = (data_out << 1) | int(dut.scrambled_data.value)

    data_out_reversed = 0

    for _ in range(64):
        data_out_reversed = (data_out_reversed << 1) | (data_out & 1)
        data_out = data_out >> 1

    print(hex(data_out_reversed))
    assert data_out_reversed == data_correct
