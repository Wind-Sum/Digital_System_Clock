`timescale 1ns / 1ps
// Generates a single-clock-wide enable pulse.  The default value assumes a
// 50 MHz board clock; override CLOCKS_PER_SECOND in simulation if desired.
module clk_div #(
    parameter integer CLOCKS_PER_SECOND = 50_000_000
)(
    input  wire clk,
    input  wire rst,
    output reg  tick_1s
);
    reg [31:0] count;

    always @(posedge clk) begin
        if (rst) begin
            count   <= 32'd0;
            tick_1s <= 1'b0;
        end else if (count == CLOCKS_PER_SECOND - 1) begin
            count   <= 32'd0;
            tick_1s <= 1'b1;
        end else begin
            count   <= count + 1'b1;
            tick_1s <= 1'b0;
        end
    end
endmodule
