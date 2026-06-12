from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_ipv4_loopback_double_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [
        Path(__file__).resolve().parent / "harness" / "tb_ipv4_loopback_double.sv"
    ]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="tb_ipv4_loopback_double",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
            f"-I{Path(__file__).resolve().parent / "harness"}",
            f"-I{proj_path / "src"}",
            f"-I{proj_path / "src" / "helpers"}",
            f"-I{proj_path / "src" / "include"}",
            f"-I{proj_path / "src" / "ipv4" / "udp"}",
            f"-I{proj_path / "src" / "ipv4" / "header"}",
            f"-I{proj_path / "src" / "ipv4"}",
        ],
    )
    runner.test(
        hdl_toplevel="tb_ipv4_loopback_double",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/tb_ipv4_loopback_double.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_ipv4_loopback_double(dut):

    data = [0x48454C4C, 0x4F20574F, 0x524C4421]

    source = AxiStreamSource(
        AxiStreamBus(dut, "s_axis"), dut.i_clk, dut.i_arst, byte_lanes=1
    )

    sink = AxiStreamSink(
        AxiStreamBus(dut, "m_axis"), dut.i_clk, dut.i_arst, byte_lanes=1
    )

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    dut.s_axis_tlen.value = 12
    cocotb.start_soon(source.send(frame))
    dut.m_axis_tready.value = 1

    await RisingEdge(dut.i_clk)

    recv_data = await sink.read()

    for tx, rx in zip(data, recv_data):
        assert tx == rx
