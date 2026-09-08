`timescale 1ns / 1ps
module led #(
    parameter integer HALF_PERIOD_CYCLES = 25_000_000
)(
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output reg  led_out
);
    reg [31:0] count;
    always @(posedge clk) begin
        if (rst || !trigger) begin
            count   <= 32'd0;
            led_out <= 1'b0;
        end else if (count == HALF_PERIOD_CYCLES - 1) begin
            count   <= 32'd0;
            led_out <= ~led_out;
        end else begin
            count <= count + 1'b1;
        end
    end
endmodule
