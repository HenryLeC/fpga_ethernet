from pathlib import Path

import cocotb
from cocotb_tools.runner import get_runner
from cocotb.triggers import Timer


def test_scrambler_runner():
    proj_path = Path(__file__).resolve().parent.parent.parent
    sources = [proj_path / "src" / "phy" / "pcs" / "tx" / "scrambler.sv"]

    runner = get_runner("verilator")
    runner.build(
        sources=sources,
        hdl_toplevel="scrambler",
        always=True,
        waves=True,
        build_args=[
            "--trace-fst",
            "--trace-structs",
        ],
    )
    runner.test(
        hdl_toplevel="scrambler",
        test_module=__name__,
        waves=True,
        test_args=["--trace-file", "../wave/scrambler.fst"],
    )


@cocotb.test()
async def test_scrambler(dut):

    # These come from https://grouper.ieee.org/groups/802/3/ae/public/jul00/walker_1_0700.pdf
    data_in = 0x000000000000001E
    data_correct = 0x7BFFF0800000001E

    dut.data_in.value = data_in
    dut.lfsr_state_in.value = (1 << 58) - 1

    await Timer(1, "ns")

    data_out = int(dut.data_out.value)
    state_out = dut.lfsr_state_out.value

    print(hex(data_out))
    assert data_out == data_correct

    data_in = 0xD555555555555578
    data_correct = 0x623016AAAAAD1578

    dut.data_in.value = data_in
    dut.lfsr_state_in.value = state_out

    await Timer(1, "ns")

    data_out = int(dut.data_out.value)
    state_out = dut.lfsr_state_out.value

    print(hex(data_out))
    assert data_out == data_correct
