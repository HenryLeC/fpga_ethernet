from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_pcie_to_data_stream_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "pcie" / "pcie_to_data_stream.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="pcie_to_data_stream",
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
        hdl_toplevel="pcie_to_data_stream",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/pcie_to_data_stream.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.pcie_axis_clk.value = 0
        dut.eth_axis_clk.value = 0
        await Timer(1, unit="ns")
        dut.pcie_axis_clk.value = 1
        dut.eth_axis_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_pcie_to_data_stream(dut):

    data = [0x00, 0x10] + [0 for _ in range(30)] + [i for i in range(0x0010)]

    source = AxiStreamSource(
        AxiStreamBus(dut, "pcie_axis"),
        dut.pcie_axis_clk,
        dut.pcie_axis_arstn,
        reset_active_level=False,
    )

    sink = AxiStreamSink(
        AxiStreamBus(dut, "eth_axis"),
        dut.eth_axis_clk,
        dut.eth_axis_arstn,
        reset_active_level=False,
    )

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.eth_axis_arstn.value = 0
    dut.pcie_axis_arstn.value = 0

    await RisingEdge(dut.eth_axis_clk)
    await RisingEdge(dut.eth_axis_clk)

    dut.eth_axis_arstn.value = 1
    dut.pcie_axis_arstn.value = 1

    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    cocotb.start_soon(source.send(frame))
    dut.eth_axis_tready.value = 1

    await RisingEdge(dut.eth_axis_clk)

    recv_data = await sink.read()

    for tx, rx in zip(data[32:], recv_data):
        assert tx == rx

    assert dut.data_length.value == 0x10
