# 多功能电子表 - 交接速记

## 当前状态

- 目标板：HX7A75C，器件 `xc7a75tfgg484-2`，Vivado 2023.2。
- 2026-09-07 已完成实板测试，时间、显示、按键、开关、闹钟解除和复位均正常。
- 实板验证过的最终位流：`Vivado_Project_File\clock\batch_build\clock_top.bit`。
- 位流 SHA-256：`3E041B215289A5F6FF66DDA2D7E54A16C0FC3F0DEA18C890C7B1B03E10FE099B`。
- 不要误用 `clock.runs\impl_1\clock_top.bit`，它早于最终数码管修复。

## 入口文件

- 用户操作唯一参考：`Question&Solution\用法.md`。
- 原始需求：`Question&Solution\多功能电子表.md`；交互设计背景：`Question&Solution\界面控制设计.md`。
- 顶层：`Vivado_Project_File\clock\clock.srcs\sources_1\new\clock_top.v`。
- RTL 目录：`clock.srcs\sources_1\new\`；测试平台：`clock.srcs\sim_1\new\clock_tb.v`；约束：`clock.srcs\constrs_1\new\clock.xdc`。

## 必须保留的板级结论

- 所有物理方向均以**数码管正放、板上文字正常阅读**为准。SW1～SW4 向上是逻辑 0，向下是逻辑 1；这与开发板手册中的方向文字相反。
- SW4 向上时 KEY4 解除正在响铃的闹钟；SW4 向下时 KEY4 全局复位。四键同时按下也是备用复位。
- SW6 必须向下才连接数码管，向上连接八组双色 LED。
- 数码管共阳，段码低有效；PNP9012 位选在 FPGA 侧也是低有效。
- 最初实板出现全屏 0/8 交替和残亮，是因为位选被写成高有效，导致多数位同时导通。`digital_tube.v` 已改为 one-cold 位选，并加入 50 个 50 MHz 周期（约 1 us）的换位消隐。
- 50 MHz 时钟为 Y18；KEY1/2 为 E3/G4（LVCMOS15），KEY3/4 为 P19/R19（LVCMOS33），按键按下为低；SW1～SW4 为 N14/P16/R17/N15；LED1 为 AA6、高电平点亮。

## 实现与验证

- 默认参数：真实 1 秒、10 ms 按键消抖、约 1 Hz 字段/LED 闪烁、约 20 ms 上电复位。
- 设置采用字段内回绕，不跨字段自动进位或借位；日期仍限制大小月和闰年。
- RTL smoke test 已通过功能测试，并断言数码管位选始终 one-cold、换位必经全灭状态。
- 最终实现：DRC 0 违规，901/901 可布线网络完成，WNS 13.868 ns，WHS 0.129 ns。
- 报告位于 `Vivado_Project_File\clock\batch_build\{drc.rpt,timing_summary.rpt,route_status.rpt}`。

在 `Vivado_Project_File\clock` 目录运行：

```powershell
& 'D:\Software\Vivado\2023.2\bin\vivado.bat' -mode batch -source run_rtl_sim.tcl
& 'D:\Software\Vivado\2023.2\bin\vivado.bat' -mode batch -source build_bitstream.tcl
```

每次修改 RTL 后必须先跑仿真，再重新生成并检查 `batch_build\clock_top.bit`。
