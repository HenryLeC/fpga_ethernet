from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus, AxiStreamSink


def test_ipv4_udp_packet_decoder_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "ipv4" / "ipv4_udp_packet_decoder.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="ipv4_udp_packet_decoder",
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
        hdl_toplevel="ipv4_udp_packet_decoder",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/ipv4_udp_packet_decoder.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_ipv4_udp_packet_decoder(dut):

    frame = [
        0x28000045,
        0x00003412,
        0x915A1140,
        0x01010101,
        0xFF01000A,
        0x80808080,
        0x00001400,
        0x48454C4C,
        0x4F20574F,
        0x524C4421,
        0x0000,
    ]

    frame_bytes = []
    for dword in frame:
        for i in range(4):
            frame_bytes.append((dword >> (i * 8)) & 0xFF)

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
    sink = AxiStreamSink(AxiStreamBus(dut, "m_axis"), dut.i_clk, dut.i_arst)

    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    frame = AxiStreamFrame(tdata=frame_bytes, tx_complete=Event())
    cocotb.start_soon(source.send(frame))

    dut.m_axis_tready.value = 0

    data_recv = await sink.read()

    for recv, correct in zip(data_recv, data):
        assert recv == correct

    assert dut.m_axis_tlen.value == 12
