from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus

import csv


def test_mac_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "mac" / "mac.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="mac",
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
        hdl_toplevel="mac",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/mac.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_txclk.value = 0
        dut.i_rxclk.value = 0
        await Timer(1, unit="ns")
        dut.i_txclk.value = 1
        dut.i_rxclk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_mac(dut):
    try:
        f = open(Path(__file__).resolve().parent / "test_data/mac_test.csv", "r")

        reader = csv.reader(f)

        data = (
            [ord(i) for i in "Hello, this is a test of pcie to udp sending."]
            + [0, 0, 0]
            + [0 for _ in range(0x10 * 15)]
        )
        assert len(data) == 0x120

        source = AxiStreamSource(
            AxiStreamBus(dut, "udp_data"),
            dut.i_txclk,
            dut.i_arst,
            reset_active_level=True,
        )
        dut.udp_data_tlength.value = 0x120

        cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

        dut.i_arst.value = 1

        await RisingEdge(dut.i_rxclk)

        dut.i_arst.value = 0

        frame = AxiStreamFrame(tdata=data, tx_complete=Event())
        cocotb.start_soon(source.send(frame))

        next(reader)
        next(reader)

        for row in reader:
            dut.i_RXC.value = int(row[-3], 16)
            dut.i_RXD.value = int(row[-2], 16)

            await RisingEdge(dut.i_rxclk)

        assert dut.o_TXC.value == 0xF
        assert dut.o_TXD.value == 0x07070707

    finally:
        f.close()
