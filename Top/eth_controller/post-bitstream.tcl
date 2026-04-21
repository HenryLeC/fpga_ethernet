set hw_target "alibaba_board_svf_target"
set fpga_device "xcku3p"

open_hw_manager

connect_hw_server
puts "connected to hw server at [current_hw_server]"

create_hw_target $hw_target
puts "current hw target [current_hw_target]"

open_hw_target

# single device on scan chain
create_hw_device -part $fpga_device
puts "scan chain : [get_hw_devices]"

set dst_dir [file normalize "$repo_path/bin/$proj_name\-$describe"]

set_property PROGRAM.FILE "$dst_dir/$proj_name-$describe.bit" [get_hw_device]

#select device to program
program_hw_device [get_hw_device]

# generate svf file
write_hw_svf -force "$dst_dir/$proj_name-$describe.svf"

close_hw_manager