`timescale 1ns / 1ps
module digital_tube #(
    parameter integer REFRESH_DIV = 5_000,
    parameter integer BLINK_DIV   = 25_000_000,
    parameter integer BLANK_CYCLES = 50
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] display_data,
    input  wire [7:0]  blink_mask,
    output reg  [7:0]  seg,//段选
    output reg  [7:0]  dig//位选
);
    reg [31:0] refresh_count;
    reg [31:0] blink_count;//闪烁计数
    reg [31:0] blank_count;//熄灭计数
    reg [2:0]  scan_index;//扫描位置索引
    reg        blink_on;//闪烁中
    reg        blanking;//熄灭中
    reg [3:0]  current_digit;

    function [7:0] decode_seg;//译码器
        input [3:0] value;
        begin
            case (value)
                4'd0: decode_seg = 8'b1100_0000;
                4'd1: decode_seg = 8'b1111_1001;
                4'd2: decode_seg = 8'b1010_0100;
                4'd3: decode_seg = 8'b1011_0000;
                4'd4: decode_seg = 8'b1001_1001;
                4'd5: decode_seg = 8'b1001_0010;
                4'd6: decode_seg = 8'b1000_0010;
                4'd7: decode_seg = 8'b1111_1000;
                4'd8: decode_seg = 8'b1000_0000;
                4'd9: decode_seg = 8'b1001_0000;
                default: decode_seg = 8'b1111_1111;
            endcase
        end
    endfunction

    always @(*) begin
        case (scan_index)
            3'd0: current_digit = display_data[31:28]; // 最左位 SEL0
            3'd1: current_digit = display_data[27:24];
            3'd2: current_digit = display_data[23:20];
            3'd3: current_digit = display_data[19:16];
            3'd4: current_digit = display_data[15:12];
            3'd5: current_digit = display_data[11:8];
            3'd6: current_digit = display_data[7:4];
            default: current_digit = display_data[3:0];
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            refresh_count <= 32'd0;
            blink_count   <= 32'd0;
            blank_count   <= 32'd0;
            scan_index    <= 3'd0;
            blink_on      <= 1'b1;
            blanking      <= 1'b1;
            seg           <= 8'hff;
            dig           <= 8'hff;
        end else begin
            if (blink_count == BLINK_DIV - 1) begin
                blink_count <= 32'd0;
                blink_on    <= ~blink_on;//闪烁实现
            end else begin
                blink_count <= blink_count + 1'b1;
            end

            if (blanking) begin//消隐态
                dig <= 8'hff;//关位选，全灭
                if (blink_mask[scan_index] && !blink_on)//写好下一刻段码
                    seg <= 8'hff;
                else//正常数字
                    seg <= decode_seg(current_digit);

                if (blank_count == BLANK_CYCLES - 1) begin//时间到退出消隐
                    blank_count <= 32'd0;
                    blanking    <= 1'b0;
                    dig         <= ~(8'b0000_0001 << scan_index);//左移低位补0
                end else begin//否则继续消隐
                    blank_count <= blank_count + 1'b1;
                end
            end else if (refresh_count == REFRESH_DIV - 1) begin//循环扫描
                refresh_count <= 32'd0;
                blank_count   <= 32'd0;
                blanking      <= 1'b1;//该次结束，进入全消隐
                dig           <= 8'hff;
                scan_index    <= scan_index + 1'b1;
            end else begin//停留
                refresh_count <= refresh_count + 1'b1;
            end
        end
    end
endmodule
