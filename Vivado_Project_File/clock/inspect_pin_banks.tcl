create_project -in_memory -part xc7a75tfgg484-2
set_property design_mode PinPlanning [current_fileset]
open_io_design -part xc7a75tfgg484-2
foreach pin {Y18 E3 G4 P19 R19 N14 P16 R17 N15 AB18 U17 U18 P14 R14 R18 T18 N17 Y19 V18 V19 AA19 AB20 V17 W17 AA18 AA6 V7 W7 AB7} {
    set package_pin [get_package_pins $pin]
    puts "$pin bank=[get_property BANK $package_pin]"
}
exit
