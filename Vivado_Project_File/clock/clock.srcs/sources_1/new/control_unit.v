`timescale 1ns / 1ps
module control_unit(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] key_pulse,
    input  wire       sw_edit_enable,
    input  wire [5:0] hour,
    input  wire [5:0] minute,
    input  wire [5:0] second,
    input  wire [6:0] year,
    input  wire [3:0] month,
    input  wire [5:0] day,
    input  wire [5:0] alarm_hour0,
    input  wire [5:0] alarm_minute0,
    input  wire [5:0] alarm_hour1,
    input  wire [5:0] alarm_minute1,
    input  wire [5:0] alarm_hour2,
    input  wire [5:0] alarm_minute2,
    input  wire [5:0] countdown_minute,
    input  wire [5:0] countdown_second,
    input  wire       alarm_active,
    output reg        time_add,
    output reg        time_sub,
    output reg        date_add,
    output reg        date_sub,
    output reg        alarm_add,
    output reg        alarm_sub,
    output reg        countdown_add,
    output reg        countdown_sub,
    output wire       edit_enable,
    output reg  [1:0] edit_field,
    output reg  [1:0] alarm_select,
    output reg        alarm_ack,
    output reg  [1:0] display_mode,
    output reg  [31:0] display_data,
    output reg  [7:0] blink_mask
);
    localparam MODE_TIME      = 2'd0;
    localparam MODE_DATE      = 2'd1;
    localparam MODE_ALARM     = 2'd2;
    localparam MODE_COUNTDOWN = 2'd3;

    reg sw_edit_enable_d;

    function [3:0] tens;
        input [6:0] value;
        begin tens = value / 10; end
    endfunction
    function [3:0] ones;
        input [6:0] value;
        begin ones = value % 10; end
    endfunction

    assign edit_enable = sw_edit_enable;

    always @(posedge clk) begin
        if (rst) begin
            display_mode <= MODE_TIME;
            edit_field  <= 2'd0;
            alarm_select <= 2'd0;
            alarm_ack   <= 1'b0;
            sw_edit_enable_d <= 1'b0;
        end else begin
            alarm_ack <= 1'b0;
            sw_edit_enable_d <= sw_edit_enable;//保存上一时刻的sw，sw上0下1
            
            if (sw_edit_enable && !sw_edit_enable_d)//上升沿触发修改，调整修改字段为0
                edit_field   <= 2'd0;

            if (key_pulse[0]) begin//摁key1
                if (sw_edit_enable) begin//修改
                    if ((display_mode == MODE_ALARM) && (edit_field == 2'd1))
                        edit_field <= 2'd0;
                    else if ((display_mode == MODE_COUNTDOWN) && (edit_field == 2'd1))
                        edit_field <= 2'd0;
                    else if ((display_mode != MODE_ALARM) &&
                             (display_mode != MODE_COUNTDOWN) &&
                             (edit_field == 2'd2))
                        edit_field <= 2'd0;
                    else
                        edit_field <= edit_field + 1'b1;
                end else begin//查看
                    display_mode <= display_mode + 1'b1;
                    edit_field   <= 2'd0;
                end
            end

            if (!sw_edit_enable && (display_mode == MODE_ALARM)) begin//闹钟页面的组别切换
                if (key_pulse[1])
                    alarm_select <= (alarm_select == 2'd0) ? 2'd2 : alarm_select - 1'b1;
                else if (key_pulse[2])
                    alarm_select <= (alarm_select == 2'd2) ? 2'd0 : alarm_select + 1'b1;
            end

            if (key_pulse[3] && alarm_active)//关闹钟
                alarm_ack <= 1'b1;
        end
    end

    always @(*) begin
        time_add      = 1'b0; time_sub      = 1'b0;
        date_add      = 1'b0; date_sub      = 1'b0;
        alarm_add     = 1'b0; alarm_sub     = 1'b0;
        countdown_add = 1'b0; countdown_sub = 1'b0;
        if (sw_edit_enable) begin//允许修改
            case (display_mode)
                MODE_TIME: begin
                    time_add = key_pulse[1]; time_sub = key_pulse[2];
                end
                MODE_DATE: begin
                    date_add = key_pulse[1]; date_sub = key_pulse[2];
                end
                MODE_ALARM: begin
                    alarm_add = key_pulse[1]; alarm_sub = key_pulse[2];
                end
                MODE_COUNTDOWN: begin
                    countdown_add = key_pulse[1]; countdown_sub = key_pulse[2];
                end
                default: ;
            endcase
        end
    end

    always @(*) begin
        blink_mask = 8'h00;//闪烁字段
        case (display_mode)
            MODE_TIME: begin
                display_data = {4'hf, 4'hf, tens(hour), ones(hour), tens(minute), ones(minute), tens(second), ones(second)};
                if (sw_edit_enable) begin
                    case (edit_field)
                        2'd0: blink_mask = 8'b0000_1100;//时闪烁
                        2'd1: blink_mask = 8'b0011_0000;//分闪烁
                        2'd2: blink_mask = 8'b1100_0000;//秒闪烁
                        default: ;
                    endcase
                end
            end
            MODE_DATE: begin
                display_data = {4'd2, 4'd0, tens(year), ones(year), tens(month), ones(month), tens(day), ones(day)};
                if (sw_edit_enable) begin
                    case (edit_field)
                        2'd0: blink_mask = 8'b0000_1100;
                        2'd1: blink_mask = 8'b0011_0000;
                        2'd2: blink_mask = 8'b1100_0000;
                        default: ;
                    endcase
                end
            end
            MODE_ALARM: begin
                case (alarm_select)//闹钟组别选择
                    2'd0: display_data = {4'hf, 4'd1, tens(alarm_hour0), ones(alarm_hour0), tens(alarm_minute0), ones(alarm_minute0), 4'hf, 4'hf};
                    2'd1: display_data = {4'hf, 4'd2, tens(alarm_hour1), ones(alarm_hour1), tens(alarm_minute1), ones(alarm_minute1), 4'hf, 4'hf};
                    default: display_data = {4'hf, 4'd3, tens(alarm_hour2), ones(alarm_hour2), tens(alarm_minute2), ones(alarm_minute2), 4'hf, 4'hf};
                endcase
                if (sw_edit_enable) begin
                    if (edit_field == 2'd0) blink_mask = 8'b0000_1100;
                    else                    blink_mask = 8'b0011_0000;
                end
            end
            default: begin//倒计时
                display_data = {4'hf, 4'hf, 4'hf, 4'hf, tens(countdown_minute), ones(countdown_minute), tens(countdown_second), ones(countdown_second)};
                if (sw_edit_enable) begin
                    case (edit_field)
                        2'd0: blink_mask = 8'b0011_0000;
                        2'd1: blink_mask = 8'b1100_0000;
                        default: ;
                    endcase
                end
            end
        endcase
    end
endmodule
