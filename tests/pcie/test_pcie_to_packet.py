from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_pcie_to_packet_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [Path(__file__).parent / "harness" / "pcie_to_packet.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="pcie_to_packet",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            "-F",
            f"{proj_path / "verilator.vc"}",
            f"-I{Path(__file__).parent.parent / "mac/mocks"}",
        ],
    )
    runner.test(
        hdl_toplevel="pcie_to_packet",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/pcie_to_packet.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_pcie_to_packet(dut):

    data = [0x01, 0x40] + [0 for _ in range(30)] + [i % 256 for i in range(0x0140)]

    source = AxiStreamSource(
        AxiStreamBus(dut, "pcie_axis"),
        dut.i_clk,
        dut.i_arst,
        reset_active_level=True,
    )

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    cocotb.start_soon(send_twice(source, data))

    for i in range(500):
        await RisingEdge(dut.i_clk)


async def send_twice(source, data):
    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    await source.send(frame)

    await source.send(frame)
