from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Event, FallingEdge, RisingEdge, Timer
from cocotbext.axi import AxiStreamFrame, AxiStreamSource, AxiStreamBus


def test_udp_packet_encode_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent

    sources = [proj_path / "src" / "ipv4" / "udp" / "udp_packet_encode.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="udp_packet_encode",
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
        hdl_toplevel="udp_packet_encode",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/udp_packet_encode.fst"],
    )


async def generate_clock(dut):
    """Generate clock pulses."""

    while True:
        dut.i_clk.value = 0
        await Timer(1, unit="ns")
        dut.i_clk.value = 1
        await Timer(1, unit="ns")


@cocotb.test()
async def test_udp_packet_encode(dut):

    data = [0x48454C4C, 0x4F20574F, 0x524C4421]

    source = AxiStreamSource(
        AxiStreamBus(dut, "s_axis"), dut.i_clk, dut.i_arst, byte_lanes=1
    )
    cocotb.start_soon(generate_clock(dut))  # run the clock "in the background"

    dut.i_arst.value = 1

    await RisingEdge(dut.i_clk)
    await RisingEdge(dut.i_clk)

    dut.i_arst.value = 0

    dut.source_port.value = 1234
    dut.destination_port.value = 8080
    dut.data_length.value = 12

    frame = AxiStreamFrame(tdata=data, tx_complete=Event())
    dut.m_axis_tready.value = 1

    cocotb.start_soon(source.send(frame))

    await RisingEdge(dut.m_axis_tvalid)
    await FallingEdge(dut.i_clk)

    packet = [0x901FD204, 0x00001400] + data

    for idx, dword in enumerate(packet):
        assert dut.m_axis_tdata.value == dword
        if idx == len(packet) - 1:
            assert dut.m_axis_tlast.value

        await FallingEdge(dut.i_clk)
