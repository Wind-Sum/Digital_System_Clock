open_project clock.xpr
set_property top clock_top [get_filesets sources_1]
launch_runs synth_1 -jobs 2
wait_on_run synth_1
open_run synth_1
report_drc -checks {UCIO-1 NSTD-1} -file xdc_drc.rpt
report_io -file xdc_io.rpt
close_project
exit
