# Standalone implementation flow.  Outputs are isolated in batch_build/ so
# this can run while the interactive Vivado project is open elsewhere.
create_project -force clock_batch batch_build -part xc7a75tfgg484-2

read_verilog clock.srcs/sources_1/new/clk_div.v
read_verilog clock.srcs/sources_1/new/time.v
read_verilog clock.srcs/sources_1/new/date.v
read_verilog clock.srcs/sources_1/new/alarm.v
read_verilog clock.srcs/sources_1/new/countdown.v
read_verilog clock.srcs/sources_1/new/led.v
read_verilog clock.srcs/sources_1/new/key_driver.v
read_verilog clock.srcs/sources_1/new/control_unit.v
read_verilog clock.srcs/sources_1/new/digital_tube.v
read_verilog clock.srcs/sources_1/new/clock_top.v

synth_design -top clock_top -part xc7a75tfgg484-2
read_xdc clock.srcs/constrs_1/new/clock.xdc
opt_design
place_design
phys_opt_design
route_design

report_timing_summary -file batch_build/timing_summary.rpt -check_timing_verbose -max_paths 10
report_drc -file batch_build/drc.rpt
report_route_status -file batch_build/route_status.rpt
write_bitstream -force batch_build/clock_top.bit
exit
