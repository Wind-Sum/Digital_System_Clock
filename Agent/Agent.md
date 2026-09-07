# 多功能电子表 - 交接速记

## 工程与最新产物

- 工作区：`D:\UniFile\Grade3\26_27_1\ShuZiXiTongKeShe\Course_Project`
- Vivado 工程：`Vivado_Project_File\clock\clock.xpr`；器件：HX7A75C / `xc7a75tfgg484-2`；Vivado 2023.2。
- 最新可上板 bitstream：`Vivado_Project_File\clock\batch_build\clock_top.bit`。
- 需求与当前交互规格：`Question&Solution\多功能电子表.md`、`Question&Solution\界面控制设计.md`。后者是按键/开关行为的优先来源。
- RTL：`Vivado_Project_File\clock\clock.srcs\sources_1\new\`；仿真：`clock.srcs\sim_1\new\clock_tb.v`；约束：`clock.srcs\constrs_1\new\clock.xdc`。

## 当前交互规则

- KEY1：查看模式循环切换时间、日期、闹钟、倒计时；编辑模式循环切换当前页面字段。
- KEY2 / KEY3：编辑模式中当前字段加一 / 减一；仅在闹钟查看页分别选择上一组 / 下一组闹钟。
- KEY4：以数码管正放为方向基准，SW4 向上（逻辑 0）时仅解除正在响铃的闹钟；SW4 向下（逻辑 1）时，KEY4 是全局复位。
- SW1：闹钟总开关，关闭会立即静音当前响铃或等待二次响铃的闹钟。
- SW2：倒计时运行/暂停。编辑其他页面不会暂停倒计时。
- SW3：查看/编辑模式；每次进入编辑均从该页第一个字段开始。
- 倒计时显示/设置为 `MM:SS`。三组闹钟在查看页通过 KEY2/KEY3 选择。
- 当前设置模式采用**字段内回绕，不自动跨字段进位/借位**：例如 9 月 30 日的“日 +1”变为 9 月 1 日；59 秒加一变为 00 秒。月份和日期上限仍按大小月、闰年约束；年份调整导致非闰年时，2 月 29 日会钳位为 2 月 28 日。

## 硬件要点

- 50 MHz 时钟：Y18；KEY1/2：E3/G4、LVCMOS15；KEY3/4：P19/R19、LVCMOS33，按下为低。
- SW1--4：N14/P16/R17/N15。以数码管正放为方向基准，物理向上为逻辑 0、物理向下为逻辑 1。LED1：AA6，高电平点亮。
- 数码管共阳：段码低有效；位选由 PNP9012 高边管驱动，FPGA 侧实测为低有效。驱动已采用“一位低有效 + 约 1 us 换位消隐”，以避免多位叠加成 0/8 和残影。以数码管正放为方向基准，上板必须将 **SW6 拨下**，否则复用管脚连接双色 LED 而非数码管。
- 顶层已按 50 MHz 配置：真实秒、10 ms 按键消抖、编辑和 LED 的完整闪烁约 1 Hz。上电复位约 20 ms；同时按下四个按键也会复位。

## 验证状态

- 最新 RTL smoke test 已通过：除查看/编辑下的 KEY1、KEY4 无副作用、闹钟组选择、SW4+KEY4 复位、倒计时跨页面编辑持续运行、SW1 立即静音外，还检查数码管位选始终 one-cold 且换位经过全灭状态。
- 最新批处理实现已通过：DRC 0 违规；901/901 可布线网络完成布线；WNS 13.868 ns，WHS 0.129 ns。
- 报告：`batch_build\drc.rpt`、`timing_summary.rpt`、`route_status.rpt`。
- `Synth 8-7080` 仅表示并行综合条件未满足，只影响构建速度；无设计错误或有害警告。
