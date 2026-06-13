from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_encoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "tx" / "encoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="encoder",
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
        hdl_toplevel="encoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/encoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_encoder(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"

    test_input_data = [
        0x07070707,
        0x07070707,
        0x555555FB,
        0xD5555555,
        0x77200008,
        0x8B0E3805,
    ]
    test_input_control = [0xF, 0xF, 0x1, 0x0, 0x0, 0x0]

    correct_output_block = [0x000000000000001E, 0xD555555555555578, 0x8B0E380577200008]
    correct_output_header = [0b01, 0b01, 0b10]

    assert len(test_input_control) == len(test_input_data)
    assert len(correct_output_block) == len(correct_output_header)

    assert len(correct_output_block) * 2 == len(test_input_data)

    for i in range(len(correct_output_block)):
        cocotb.log.info(f"Iteration: {i}")
        dut.TXD.value = test_input_data[2 * i] + (test_input_data[2 * i + 1] << 32)
        dut.TXC.value = test_input_control[2 * i] + (test_input_control[2 * i + 1] << 4)

        await FallingEdge(dut.clk)

        assert dut.data.value == correct_output_block[i]
        assert dut.header.value == correct_output_header[i]
