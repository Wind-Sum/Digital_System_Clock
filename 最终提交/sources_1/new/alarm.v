`timescale 1ns / 1ps
module alarm(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1s,
    input  wire [5:0] hour,
    input  wire [5:0] minute,
    input  wire [5:0] second,
    input  wire       alarm_enable,
    input  wire       edit_enable,
    input  wire [1:0] edit_field, // 0: 小时, 1: 分钟
    input  wire       add,
    input  wire       sub,
    input  wire [1:0] alarm_select,
    input  wire       acknowledge,
    output reg  [5:0] alarm_hour0,
    output reg  [5:0] alarm_minute0,
    output reg  [5:0] alarm_hour1,
    output reg  [5:0] alarm_minute1,
    output reg  [5:0] alarm_hour2,
    output reg  [5:0] alarm_minute2,
    output reg        alarm_trigger
);
    reg [3:0] phase_count;
    reg       waiting;
    reg       second_ring;

    wire selected_match =
        ((hour == alarm_hour0) && (minute == alarm_minute0)) ||
        ((hour == alarm_hour1) && (minute == alarm_minute1)) ||
        ((hour == alarm_hour2) && (minute == alarm_minute2));

    task adjust_selected;//调整数值自适应
        input increment;//增or减
        begin
            case (alarm_select)
                2'd0: if (edit_field == 2'd0)
                          alarm_hour0 <= increment ? ((alarm_hour0 == 6'd23) ? 6'd0 : alarm_hour0 + 1'b1) : ((alarm_hour0 == 6'd0) ? 6'd23 : alarm_hour0 - 1'b1);
                      else if (edit_field == 2'd1)
                          alarm_minute0 <= increment ? ((alarm_minute0 == 6'd59) ? 6'd0 : alarm_minute0 + 1'b1) : ((alarm_minute0 == 6'd0) ? 6'd59 : alarm_minute0 - 1'b1);
                2'd1: if (edit_field == 2'd0)
                          alarm_hour1 <= increment ? ((alarm_hour1 == 6'd23) ? 6'd0 : alarm_hour1 + 1'b1) : ((alarm_hour1 == 6'd0) ? 6'd23 : alarm_hour1 - 1'b1);
                      else if (edit_field == 2'd1)
                          alarm_minute1 <= increment ? ((alarm_minute1 == 6'd59) ? 6'd0 : alarm_minute1 + 1'b1) : ((alarm_minute1 == 6'd0) ? 6'd59 : alarm_minute1 - 1'b1);
                2'd2: if (edit_field == 2'd0)
                          alarm_hour2 <= increment ? ((alarm_hour2 == 6'd23) ? 6'd0 : alarm_hour2 + 1'b1) : ((alarm_hour2 == 6'd0) ? 6'd23 : alarm_hour2 - 1'b1);
                      else if (edit_field == 2'd1)
                          alarm_minute2 <= increment ? ((alarm_minute2 == 6'd59) ? 6'd0 : alarm_minute2 + 1'b1) : ((alarm_minute2 == 6'd0) ? 6'd59 : alarm_minute2 - 1'b1);
                default: ;
            endcase
        end
    endtask

    always @(posedge clk) begin
        if (rst) begin
            alarm_hour0  <= 6'd7;  alarm_minute0 <= 6'd0;
            alarm_hour1  <= 6'd12; alarm_minute1 <= 6'd0;
            alarm_hour2  <= 6'd18; alarm_minute2 <= 6'd0;
            alarm_trigger <= 1'b0;
            phase_count   <= 4'd0;
            waiting       <= 1'b0;
            second_ring   <= 1'b0;
        end else begin
            if (edit_enable && add && !sub)
                adjust_selected(1'b1);
            else if (edit_enable && sub && !add)
                adjust_selected(1'b0);

            if (!alarm_enable) begin//不允许响铃
                alarm_trigger <= 1'b0;
                waiting       <= 1'b0;
                phase_count   <= 4'd0;
                second_ring   <= 1'b0;
            end else if (acknowledge && alarm_trigger) begin//响铃时确认
                alarm_trigger <= 1'b0;
                waiting       <= 1'b0;
                phase_count   <= 4'd0;
                second_ring   <= 1'b0;
            end else if (tick_1s) begin
                if (alarm_trigger) begin//如果触发，响铃
                    if (phase_count == 4'd4) begin
                        alarm_trigger <= 1'b0;
                        phase_count   <= 4'd0;
                        if (second_ring) begin
                            second_ring <= 1'b0;
                        end else begin
                            waiting <= 1'b1;
                        end
                    end else begin
                        phase_count <= phase_count + 1'b1;
                    end
                end else if (waiting) begin//等待10秒
                    if (phase_count == 4'd9) begin
                        waiting       <= 1'b0;
                        alarm_trigger <= 1'b1;
                        second_ring   <= 1'b1;
                        phase_count   <= 4'd0;
                    end else begin
                        phase_count <= phase_count + 1'b1;
                    end
                end else if (alarm_enable && second == 6'd0 && selected_match) begin//触发闹钟
                    alarm_trigger <= 1'b1;
                    phase_count   <= 4'd0;
                    second_ring   <= 1'b0;
                end
            end
        end
    end
endmodule
