from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_decoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "rx" / "decoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="decoder",
        always=True,
        waves=True,
        build_args=["--trace-fst", "--trace-structs", f"-I{proj_path / "src"}"],
    )
    runner.test(
        hdl_toplevel="decoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../decoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_decoder(dut):
    """Try accessing the design."""

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.arst_n.value = 0

    await Timer(5, unit="ns")  # wait a bit
    await FallingEdge(dut.clk)  # wait for falling edge/"negedge"
    dut.arst_n.value = 1

    test_block = [0x000000000000001E, 0xD555555555555578, 0x8B0E380577200008]
    test_header = [0b01, 0b01, 0b10]

    correct_rx_data = [
        0x0707070707070707,
        0xD5555555555555FB,
        0x8B0E380577200008,
    ]
    correct_rx_header = [0xFF, 0x01, 0x00]

    assert len(test_block) == len(test_header)
    assert len(correct_rx_data) == len(correct_rx_header)

    assert len(test_block) == len(correct_rx_data)

    for i in range(len(correct_rx_data)):
        cocotb.log.info(f"Iteration: {i}")
        dut.rx_data.value = test_block[i]
        dut.rx_header.value = test_header[i]

        await FallingEdge(dut.clk)
        await FallingEdge(dut.clk)

        assert dut.RXD.value == correct_rx_data[i]
        assert dut.RXC.value == correct_rx_header[i]
