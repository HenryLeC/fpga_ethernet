# False path constraints
# ----------------------------------------------------------------------------------------------------------------------
set_false_path -to [get_cells -hierarchical -filter {NAME =~ *bit_synchronizer*inst/i_in_meta_reg}] -quiet
##set_false_path -to [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_*_reg}] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_meta*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync1*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync2*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_sync3*}]] -quiet
set_false_path -to [get_pins -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~ *reset_synchronizer*inst/rst_in_out*}]] -quiet



###  for exdes

create_waiver -internal -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_rx_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*/bit_synchronizer_rx_init_done_inst/i_in_meta_reg}]]

          
create_waiver -internal -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_rx_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*/example_*_reset_synchronizer_inst/rst_in_meta_reg}]]

create_waiver -internal -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_rx_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*/example_*_reset_synchronizer_inst/rst_in_meta_reg}]]



create_waiver -internal -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 Paths between support blocks like vio and exdes inst" \
                        -scope -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*/example_*_reset_synchronizer_inst/rst_in_meta_reg}]]
  
create_waiver -internal -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 Paths between support blocks like vio and exdes inst" \
                        -scope -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*/example_*_reset_synchronizer_inst/rst_in_meta_reg}]]

create_waiver -internal -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 Paths between support blocks like vio and exdes inst" \
                        -scope -to [get_pins -quiet -filter {REF_PIN_NAME=~*PRE} -of_objects [get_cells -hierarchical -filter {NAME =~*/example_*_reset_synchronizer_inst/rst_in_meta_reg}]]



create_waiver -internal -type CDC -id {CDC-10} -user gtwizard_ultrascale -tags "1165536" -description "CDC-10 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_*x_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*/bit_synchronizer_*x_init_done_inst/i_in_meta_reg}]]

create_waiver -internal -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_*x_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~bit_synchronizer_vio_gtwiz_reset_*x_done_*_inst/i_in_meta_reg}]]

create_waiver -internal -type CDC -id {CDC-11} -user gtwizard_ultrascale -tags "1165536" -description "CDC-11 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_*x_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*/bit_synchronizer_*x_init_done_inst/i_in_meta_reg}]]

create_waiver -internal -type CDC -id {CDC-12} -user gtwizard_ultrascale -tags "1165536" -description "CDC-12 In exdes and vio path" -scope -from [get_pins -quiet -filter {REF_PIN_NAME=~*C} -of_objects [get_cells -hierarchical -filter {NAME=~*/reset_synchronizer_*x_done_inst/rst_in_out_reg}]] -to [get_pins -quiet -filter {REF_PIN_NAME=~*D} -of_objects [get_cells -hierarchical -filter {NAME =~*/bit_synchronizer_*x_init_done_inst/i_in_meta_reg}]]

