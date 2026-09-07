# HX7A75C HDL board (XC7A75T-2FGG484-2)
# The board's 50 MHz oscillator feeds the global clock input at Y18.
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 20.000 [get_ports clk]

# Bank 0 configures from the board's 3.3 V QSPI Flash (N25Q128).
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# KEY1/KEY2 (key[0:1]) belong to Bank 35 and are pulled up to 1.5 V.
# KEY3/KEY4 (key[2:3]) are in Bank 14 and are pulled up to 3.3 V.
# All keys are active-low: pressed = 0, released = 1.
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS15} [get_ports {key[0]}]
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS15} [get_ports {key[1]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports {key[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {key[3]}]

# SW1--SW4 are 3.3 V inputs.  With the seven-segment display upright, the
# physical upper position reads 0 and the lower position reads 1.
# SW4-low (physical up) makes KEY4 acknowledge an alarm; SW4-high
# (physical down) makes KEY4 reset the design.
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

# Eight common-anode seven-segment lines, DIG0=a through DIG7=decimal point.
# Segment data is active-low in digital_tube.v.
set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN U17  IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN U18  IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN P14  IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN R14  IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN R18  IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN T18  IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN N17  IOSTANDARD LVCMOS33} [get_ports {seg[7]}]

# SEL0--SEL7 select digits from left to right.  Although the board-manual
# prose calls them active-high, the PNP9012 high-side driver schematic and
# board testing show that the FPGA-facing SEL signals are active-low.
set_property -dict {PACKAGE_PIN Y19  IOSTANDARD LVCMOS33} [get_ports {dig[0]}]
set_property -dict {PACKAGE_PIN V18  IOSTANDARD LVCMOS33} [get_ports {dig[1]}]
set_property -dict {PACKAGE_PIN V19  IOSTANDARD LVCMOS33} [get_ports {dig[2]}]
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports {dig[3]}]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33} [get_ports {dig[4]}]
set_property -dict {PACKAGE_PIN V17  IOSTANDARD LVCMOS33} [get_ports {dig[5]}]
set_property -dict {PACKAGE_PIN W17  IOSTANDARD LVCMOS33} [get_ports {dig[6]}]
set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVCMOS33} [get_ports {dig[7]}]

# LED1 is a discrete LED connected to Bank 34. It lights on a logic 1.
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports led_out]

# With the seven-segment display upright, SW6 must be in its lower position
# to connect the shared DIG/SEL pins to the seven-segment display rather than
# to the eight dual-colour LEDs.
