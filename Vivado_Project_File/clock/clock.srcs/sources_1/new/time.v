`timescale 1ns / 1ps
module time_counter(
    input  wire       clk,
    input  wire       rst,
    input  wire       tick_1s,
    input  wire       edit_enable,
    input  wire [1:0] edit_field, // 0: Ğ¡Ê±, 1: ·ÖÖÓ, 2: Ãë?
    input  wire       add,
    input  wire       sub,
    output reg  [5:0] hour,
    output reg  [5:0] minute,
    output reg  [5:0] second,
    output reg        day_tick
);
    always @(posedge clk) begin
        day_tick <= 1'b0;
        if (rst) begin
            hour   <= 6'd0;
            minute <= 6'd0;
            second <= 6'd0;
        end else if (edit_enable) begin
            if (add && !sub) begin
                case (edit_field)
                    2'd0: hour   <= (hour   == 6'd23) ? 6'd0 : hour   + 1'b1;
                    2'd1: minute <= (minute == 6'd59) ? 6'd0 : minute + 1'b1;
                    2'd2: second <= (second == 6'd59) ? 6'd0 : second + 1'b1;
                    default: ;
                endcase
            end else if (sub && !add) begin
                case (edit_field)
                    2'd0: hour   <= (hour   == 6'd0) ? 6'd23 : hour   - 1'b1;
                    2'd1: minute <= (minute == 6'd0) ? 6'd59 : minute - 1'b1;
                    2'd2: second <= (second == 6'd0) ? 6'd59 : second - 1'b1;
                    default: ;
                endcase
            end
        end else if (tick_1s) begin
            if (second == 6'd59) begin
                second <= 6'd0;
                if (minute == 6'd59) begin
                    minute <= 6'd0;
                    if (hour == 6'd23) begin
                        hour     <= 6'd0;
                        day_tick <= 1'b1;
                    end else begin
                        hour <= hour + 1'b1;
                    end
                end else begin
                    minute <= minute + 1'b1;
                end
            end else begin
                second <= second + 1'b1;
            end
        end
    end
endmodule
