`timescale 1ns / 1ps
// Active-low push-button debouncer.  key_pulse is one clock wide per press.
module key_driver #(
    parameter integer DEBOUNCE_CYCLES = 500_000
)(
    input  wire       clk,
    input  wire       rst,
    input  wire [3:0] key,
    output reg  [3:0] key_pulse
);
    reg [3:0] sync0, sync1, stable;
    reg [31:0] debounce_count [0:3];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            sync0     <= 4'b1111;
            sync1     <= 4'b1111;
            stable    <= 4'b1111;
            key_pulse <= 4'b0000;
            for (i = 0; i < 4; i = i + 1)
                debounce_count[i] <= 32'd0;
        end else begin
            sync0     <= key;
            sync1     <= sync0;
            key_pulse <= 4'b0000;
            for (i = 0; i < 4; i = i + 1) begin
                if (sync1[i] == stable[i]) begin
                    debounce_count[i] <= 32'd0;
                end else if (debounce_count[i] == DEBOUNCE_CYCLES - 1) begin
                    if (stable[i] && !sync1[i])
                        key_pulse[i] <= 1'b1;
                    stable[i]         <= sync1[i];
                    debounce_count[i] <= 32'd0;
                end else begin
                    debounce_count[i] <= debounce_count[i] + 1'b1;
                end
            end
        end
    end
endmodule
