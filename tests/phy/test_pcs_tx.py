from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import FallingEdge, Timer


def test_pcs_tx_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "tx" / "pcs_tx.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="pcs_tx",
        parameters={"LFSR_INITIAL_STATE": "58'hFFFFFFFFFFFFFFF"},
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            f"-I{proj_path / "src"}",
            f"-I{proj_path / "src" / "include"}",
            f"-I{proj_path / "src" / "phy" / "pcs" / "tx"}",
        ],
    )
    runner.test(
        hdl_toplevel="pcs_tx",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/pcs_tx.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_pcs_tx(dut):

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    # These come from https://grouper.ieee.org/groups/802/3/ae/public/jul00/walker_1_0700.pdf
    TXD_in = [0x07070707, 0x07070707, 0x555555FB, 0xD5555555]
    TXC_in = [0xF, 0xF, 0x1, 0x0]
    data_out = [0x0000001E, 0x7BFFF080, 0xAAAD1578, 0x623016AA]
    header_out = [0b01, 0b01]

    for i in range(len(header_out)):
        if i != 0:
            assert dut.header_valid.value == 1
            assert dut.tx_header.value == header_out[i - 1]
            assert dut.tx_data.value == data_out[(i - 1) * 2]
        dut.TXD.value = TXD_in[i * 2]
        dut.TXC.value = TXC_in[i * 2]

        await FallingEdge(dut.clk)

        if i != 0:
            assert dut.header_valid.value == 0
            assert dut.tx_data.value == data_out[(i - 1) * 2 + 1]
        dut.TXD.value = TXD_in[i * 2 + 1]
        dut.TXC.value = TXC_in[i * 2 + 1]

        await FallingEdge(dut.clk)

    assert dut.header_valid.value == 1
    assert dut.tx_header.value == header_out[-1]
    assert dut.tx_data.value == data_out[-2]

    await FallingEdge(dut.clk)

    assert dut.header_valid.value == 0
    assert dut.tx_data.value == data_out[-1]
