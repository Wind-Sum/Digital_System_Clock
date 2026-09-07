`timescale 1ns / 1ps
module countdown(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1s,
    input  wire       countdown_enable,
    input  wire       edit_enable,
    input  wire [1:0] edit_field, // 0: minute, 1: second
    input  wire       add,
    input  wire       sub,
    output reg  [5:0] minute,
    output reg  [5:0] second,
    output reg        countdown_finish
);
    reg [2:0] finish_seconds;
    reg       completed;

    always @(posedge clk) begin
        if (rst) begin
            minute           <= 6'd1;
            second           <= 6'd0;
            countdown_finish <= 1'b0;
            finish_seconds   <= 3'd0;
            completed        <= 1'b0;
        end else if (edit_enable) begin
            completed <= 1'b0;
            if (add && !sub) begin
                case (edit_field)
                    2'd0: minute <= (minute == 6'd59) ? 6'd0 : minute + 1'b1;
                    2'd1: second <= (second == 6'd59) ? 6'd0 : second + 1'b1;
                    default: ;
                endcase
            end else if (sub && !add) begin
                case (edit_field)
                    2'd0: minute <= (minute == 6'd0) ? 6'd59 : minute - 1'b1;
                    2'd1: second <= (second == 6'd0) ? 6'd59 : second - 1'b1;
                    default: ;
                endcase
            end
        end else if (tick_1s) begin
            if (countdown_finish) begin
                if (finish_seconds == 3'd4) begin
                    countdown_finish <= 1'b0;
                    finish_seconds   <= 3'd0;
                end else begin
                    finish_seconds <= finish_seconds + 1'b1;
                end
            end else if (countdown_enable && !completed) begin
                if ((minute == 6'd0) && (second == 6'd0)) begin
                    completed <= 1'b1; // do not ring for an unconfigured zero timer
                end else if ((minute == 6'd0) && (second == 6'd1)) begin
                    second           <= 6'd0;
                    countdown_finish <= 1'b1;
                    finish_seconds   <= 3'd0;
                    completed        <= 1'b1;
                end else if (second != 6'd0) begin
                    second <= second - 1'b1;
                end else begin
                    second <= 6'd59;
                    minute <= minute - 1'b1;
                end
            end
        end
    end
endmodule
