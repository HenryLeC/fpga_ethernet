from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_axis_width_convert_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "pcie" / "axis_width_convert.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="axis_width_convert",
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
        hdl_toplevel="axis_width_convert",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/axis_width_convert.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.axis_clk.value = 0
        await Timer(1, unit="ns")
        dut.axis_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_axis_width_convert(dut):

    data = [i for i in range(250)]

    source = AxiStreamSource(
        AxiStreamBus(dut, "s_axis"),
        dut.axis_clk,
        dut.axis_arstn,
        reset_active_level=False,
    )

    sink = AxiStreamSink(
        AxiStreamBus(dut, "m_axis"),
        dut.axis_clk,
        dut.axis_arstn,
        reset_active_level=False,
    )

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.axis_arstn.value = 0

    await RisingEdge(dut.axis_clk)
    await RisingEdge(dut.axis_clk)

    dut.axis_arstn.value = 1

    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    cocotb.start_soon(source.send(frame))
    dut.m_axis_tready.value = 1

    await RisingEdge(dut.axis_clk)

    recv_data = await sink.read()

    for tx, rx in zip(data, recv_data):
        assert tx == rx
