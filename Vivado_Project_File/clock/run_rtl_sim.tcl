# Batch RTL smoke test for the project testbench.
open_project clock.xpr
set_property top clock_top [get_filesets sources_1]
set_property top clock_tb [get_filesets sim_1]
launch_simulation
run all
close_sim
close_project
exit
