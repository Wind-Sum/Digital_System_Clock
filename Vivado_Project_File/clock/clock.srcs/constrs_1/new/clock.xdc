# HX7A75C HDL 开发板 (XC7A75T-2FGG484-2)
# 板载 50 MHz 晶振接入全局时钟输入引脚 Y18。
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports clk]
create_clock -name sys_clk -period 20.000 [get_ports clk]

# Bank 0 由板载 3.3 V QSPI Flash (N25Q128) 配置启动。
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# KEY1/KEY2 (key[0:1]) 位于 Bank 35，内部上拉到 1.5 V。
# KEY3/KEY4 (key[2:3]) 位于 Bank 14，内部上拉到 3.3 V。
# 所有按键均为低有效：按下 = 0，松开 = 1。
set_property -dict {PACKAGE_PIN E3  IOSTANDARD LVCMOS15} [get_ports {key[0]}]
set_property -dict {PACKAGE_PIN G4  IOSTANDARD LVCMOS15} [get_ports {key[1]}]
set_property -dict {PACKAGE_PIN P19 IOSTANDARD LVCMOS33} [get_ports {key[2]}]
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports {key[3]}]

# SW1--SW4 为 3.3 V 输入。以七段数码管正放为准，物理向上读到 0，向下读到 1。
# SW4 为低(物理向上)时，KEY4 用于解除闹钟；SW4 为高(物理向下)时，
# KEY4 用于复位整个设计。
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {sw[0]}]
set_property -dict {PACKAGE_PIN P16 IOSTANDARD LVCMOS33} [get_ports {sw[1]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {sw[2]}]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {sw[3]}]

# 八根共阳七段数码管段线，DIG0=a 到 DIG7=小数点。
# 段码数据在 digital_tube.v 中为低有效。
set_property -dict {PACKAGE_PIN AB18 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN U17  IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN U18  IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN P14  IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN R14  IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN R18  IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN T18  IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN N17  IOSTANDARD LVCMOS33} [get_ports {seg[7]}]

# SEL0--SEL7 从左到右选择数码管位。虽然开发板手册文字称之为高有效，
# 但结合 PNP9012 高侧驱动原理图并经过实板测试，面向 FPGA 的 SEL 信号实际为低有效。
set_property -dict {PACKAGE_PIN Y19  IOSTANDARD LVCMOS33} [get_ports {dig[0]}]
set_property -dict {PACKAGE_PIN V18  IOSTANDARD LVCMOS33} [get_ports {dig[1]}]
set_property -dict {PACKAGE_PIN V19  IOSTANDARD LVCMOS33} [get_ports {dig[2]}]
set_property -dict {PACKAGE_PIN AA19 IOSTANDARD LVCMOS33} [get_ports {dig[3]}]
set_property -dict {PACKAGE_PIN AB20 IOSTANDARD LVCMOS33} [get_ports {dig[4]}]
set_property -dict {PACKAGE_PIN V17  IOSTANDARD LVCMOS33} [get_ports {dig[5]}]
set_property -dict {PACKAGE_PIN W17  IOSTANDARD LVCMOS33} [get_ports {dig[6]}]
set_property -dict {PACKAGE_PIN AA18 IOSTANDARD LVCMOS33} [get_ports {dig[7]}]

# LED1 是连接到 Bank 34 的独立 LED，逻辑 1 时点亮。
set_property -dict {PACKAGE_PIN AA6 IOSTANDARD LVCMOS33} [get_ports led_out]

# 以七段数码管正放为准，SW6 必须处于下方的位置，
# 才能把共用的 DIG/SEL 引脚接到七段数码管，而不是接到八组双色 LED。
