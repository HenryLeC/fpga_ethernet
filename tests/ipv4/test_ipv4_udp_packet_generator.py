from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_udp_packet_encode_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "ipv4" / "ipv4_udp_packet_generator.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="ipv4_udp_packet_generator",
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
        hdl_toplevel="ipv4_udp_packet_generator",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/ipv4_udp_packet_generator.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_ipv4_udp_packet_generator(dut):

    data = [
        0x4C,
        0x4C,
        0x45,
        0x48,
        0x4F,
        0x57,
        0x20,
        0x4F,
        0x21,
        0x44,
        0x4C,
        0x52,
    ]

    source = AxiStreamSource(AxiStreamBus(dut, "s_axis"), dut.i_clk, dut.i_arst)

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    dut.s_axis_tlen.value = 12
    cocotb.start_soon(source.send(frame))
    dut.m_axis_tready.value = 0

    for i in range(10):
        await RisingEdge(dut.i_clk)

    sink = AxiStreamSink(AxiStreamBus(dut, "m_axis"), dut.i_clk, dut.i_arst)
    data = await sink.read()

    correct_frame = [
        0x00450008,
        0x34122800,
        0x11400000,
        0x0101915A,
        0x000A0101,
        0x8080FF01,
        0x14008080,
        0x4C4C0000,
        0x574F4845,
        0x44214F20,
        0x0000524C,
    ]

    correct_bytes = []
    for dword in correct_frame:
        correct_bytes += [
            dword & 0xFF,
            (dword >> 8) & 0xFF,
            (dword >> 16) & 0xFF,
            (dword >> 24) & 0xFF,
        ]

    for recv, correct in zip(data, correct_bytes):
        assert recv == correct
