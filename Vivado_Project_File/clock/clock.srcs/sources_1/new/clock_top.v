`timescale 1ns / 1ps
// Board-level top module.
// key[3:0] are active-low push buttons.  Switch allocation is documented in
// control_unit.v; sw[3] is an alarm-selection modifier on the alarm page.
module clock_top #(
    parameter integer CLOCKS_PER_SECOND = 50_000_000,
    parameter integer DEBOUNCE_CYCLES   = 500_000,
    parameter integer DISPLAY_REFRESH_DIV = 5_000,
    parameter integer DISPLAY_BLANK_CYCLES = 50,
    parameter integer BLINK_DIV         = 25_000_000,
    parameter integer LED_HALF_PERIOD   = 25_000_000,
    parameter integer POWER_ON_RESET_CYCLES = 1_000_000
)(
    input  wire       clk,
    input  wire [3:0] key,
    input  wire [3:0] sw,
    output wire [7:0] seg,
    output wire [7:0] dig,
    output wire       led_out
);
    // The board has no dedicated user reset input.  Hold the design in reset
    // during configuration start-up. SW4 selects KEY4 as a manual reset;
    // pressing all four active-low keys also remains a manual-reset shortcut.
    reg [31:0] power_on_count = 32'd0;
    reg        power_on_done  = 1'b0;
    wire       rst = !power_on_done || (~|key) || (sw[3] && !key[3]);

    always @(posedge clk) begin
        if (!power_on_done) begin
            if (power_on_count == POWER_ON_RESET_CYCLES - 1)
                power_on_done <= 1'b1;
            else
                power_on_count <= power_on_count + 1'b1;
        end
    end

    wire tick_1s;
    wire [3:0] key_pulse;
    wire [5:0] hour, minute, second;
    wire [6:0] year;
    wire [3:0] month;
    wire [5:0] day;
    wire day_tick;

    wire time_add, time_sub, date_add, date_sub;
    wire alarm_add, alarm_sub, countdown_add, countdown_sub;
    wire edit_enable;
    wire [1:0] edit_field;
    wire [1:0] alarm_select;
    wire alarm_ack;
    wire [1:0] display_mode;
    wire [31:0] display_data;
    wire [7:0] blink_mask;

    wire [5:0] alarm_hour0, alarm_minute0, alarm_hour1, alarm_minute1, alarm_hour2, alarm_minute2;
    wire alarm_trigger;
    wire [5:0] countdown_minute, countdown_second;
    wire countdown_finish;

    clk_div #(.CLOCKS_PER_SECOND(CLOCKS_PER_SECOND)) u_clk_div (
        .clk(clk), .rst(rst), .tick_1s(tick_1s)
    );
    key_driver #(.DEBOUNCE_CYCLES(DEBOUNCE_CYCLES)) u_key_driver (
        .clk(clk), .rst(rst), .key(key), .key_pulse(key_pulse)
    );
    time_counter u_time (
        .clk(clk), .rst(rst), .tick_1s(tick_1s),
        .edit_enable(edit_enable && (display_mode == 2'd0)),
        .edit_field(edit_field), .add(time_add), .sub(time_sub), .hour(hour),
        .minute(minute), .second(second), .day_tick(day_tick)
    );
    date_counter u_date (
        .clk(clk), .rst(rst), .day_tick(day_tick),
        .edit_enable(edit_enable && (display_mode == 2'd1)),
        .edit_field(edit_field), .add(date_add), .sub(date_sub), .year(year),
        .month(month), .day(day)
    );
    alarm u_alarm (
        .clk(clk), .rst(rst), .tick_1s(tick_1s), .hour(hour), .minute(minute),
        .second(second), .alarm_enable(sw[0]),
        .edit_enable(edit_enable && (display_mode == 2'd2)),
        .edit_field(edit_field), .add(alarm_add), .sub(alarm_sub),
        .alarm_select(alarm_select), .acknowledge(alarm_ack),
        .alarm_hour0(alarm_hour0), .alarm_minute0(alarm_minute0),
        .alarm_hour1(alarm_hour1), .alarm_minute1(alarm_minute1),
        .alarm_hour2(alarm_hour2), .alarm_minute2(alarm_minute2),
        .alarm_trigger(alarm_trigger)
    );
    countdown u_countdown (
        .clk(clk), .rst(rst), .tick_1s(tick_1s), .countdown_enable(sw[1]),
        .edit_enable(edit_enable && (display_mode == 2'd3)),
        .edit_field(edit_field), .add(countdown_add),
        .sub(countdown_sub), .minute(countdown_minute),
        .second(countdown_second), .countdown_finish(countdown_finish)
    );
    control_unit u_control (
        .clk(clk), .rst(rst), .key_pulse(key_pulse), .sw_edit_enable(sw[2]),
        .hour(hour), .minute(minute), .second(second), .year(year), .month(month), .day(day),
        .alarm_hour0(alarm_hour0), .alarm_minute0(alarm_minute0),
        .alarm_hour1(alarm_hour1), .alarm_minute1(alarm_minute1),
        .alarm_hour2(alarm_hour2), .alarm_minute2(alarm_minute2),
        .countdown_minute(countdown_minute), .countdown_second(countdown_second),
        .alarm_active(alarm_trigger),
        .time_add(time_add), .time_sub(time_sub), .date_add(date_add), .date_sub(date_sub),
        .alarm_add(alarm_add), .alarm_sub(alarm_sub), .countdown_add(countdown_add),
        .countdown_sub(countdown_sub), .edit_enable(edit_enable), .edit_field(edit_field),
        .alarm_select(alarm_select), .alarm_ack(alarm_ack), .display_mode(display_mode),
        .display_data(display_data), .blink_mask(blink_mask)
    );
    digital_tube #(
        .REFRESH_DIV(DISPLAY_REFRESH_DIV), .BLINK_DIV(BLINK_DIV),
        .BLANK_CYCLES(DISPLAY_BLANK_CYCLES)
    ) u_display (
        .clk(clk), .rst(rst), .display_data(display_data), .blink_mask(blink_mask),
        .seg(seg), .dig(dig)
    );
    led #(.HALF_PERIOD_CYCLES(LED_HALF_PERIOD)) u_led (
        .clk(clk), .rst(rst), .trigger(alarm_trigger | countdown_finish), .led_out(led_out)
    );
endmodule
