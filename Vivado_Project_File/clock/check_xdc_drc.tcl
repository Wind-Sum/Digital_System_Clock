open_checkpoint clock.runs/synth_1/clock_top.dcp
read_xdc clock.srcs/constrs_1/new/clock.xdc
report_drc -checks {UCIO-1 NSTD-1} -file xdc_drc.rpt
report_io -file xdc_io.rpt
exit
