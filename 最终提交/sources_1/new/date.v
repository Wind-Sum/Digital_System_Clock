`timescale 1ns / 1ps
module date_counter(
    input  wire       clk,
    input  wire       rst,
    input  wire       day_tick,
    input  wire       edit_enable,
    input  wire [1:0] edit_field, // 0: 年, 1: 月, 2: 日
    input  wire       add,
    input  wire       sub,
    output reg  [6:0] year,
    output reg  [3:0] month,
    output reg  [5:0] day
);
    function [5:0] days_in_month;
        input [6:0] y;
        input [3:0] m;
        begin
            case (m)
                4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: days_in_month = 6'd31;
                4'd4, 4'd6, 4'd9, 4'd11:                 days_in_month = 6'd30;
                4'd2: days_in_month = (y[1:0] == 2'b00) ? 6'd29 : 6'd28;
                default: days_in_month = 6'd31;
            endcase
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            year  <= 7'd26; // 2026
            month <= 4'd1;
            day   <= 6'd1;
        end else if (edit_enable) begin
            if (add && !sub) begin
                case (edit_field)
                    2'd0: begin
                        year <= (year == 7'd99) ? 7'd0 : year + 1'b1; //下一个上升沿才改
                        if ((year[1:0] == 2'b00) && month == 4'd2 && day == 6'd29)
                            day <= 6'd28;
                    end
                    2'd1: begin
                        month <= (month == 4'd12) ? 4'd1 : month + 1'b1;
                        if (day > days_in_month(year, (month == 4'd12) ? 4'd1 : month + 1'b1))
                            day <= days_in_month(year, (month == 4'd12) ? 4'd1 : month + 1'b1);
                    end
                    2'd2: day <= (day == days_in_month(year, month)) ? 6'd1 : day + 1'b1;
                    default: ;
                endcase
            end else if (sub && !add) begin
                case (edit_field)
                    2'd0: begin
                        year <= (year == 7'd0) ? 7'd99 : year - 1'b1;
                        if ((year[1:0] == 2'b00) && month == 4'd2 && day == 6'd29)
                            day <= 6'd28;
                    end
                    2'd1: begin
                        month <= (month == 4'd1) ? 4'd12 : month - 1'b1;
                        if (day > days_in_month(year, (month == 4'd1) ? 4'd12 : month - 1'b1))
                            day <= days_in_month(year, (month == 4'd1) ? 4'd12 : month - 1'b1);
                    end
                    2'd2: day <= (day == 6'd1) ? days_in_month(year, month) : day - 1'b1;
                    default: ;
                endcase
            end
        end else if (day_tick) begin
            if (day == days_in_month(year, month)) begin
                day <= 6'd1;
                if (month == 4'd12) begin
                    month <= 4'd1;
                    year  <= (year == 7'd99) ? 7'd0 : year + 1'b1;
                end else begin
                    month <= month + 1'b1;
                end
            end else begin
                day <= day + 1'b1;
            end
        end
    end
endmodule
