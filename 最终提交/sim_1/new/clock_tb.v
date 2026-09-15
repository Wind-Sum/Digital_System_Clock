`timescale 1ns / 1ps
module clock_tb;
    reg clk = 1'b0;
    reg [3:0] key = 4'b1111;
    reg [3:0] sw  = 4'b0000;
    wire [7:0] seg, dig;
    wire led_out;

    reg  alarm_test_rst = 1'b1;
    reg  alarm_test_enable = 1'b0;
    reg  alarm_test_ack = 1'b0;
    wire alarm_test_trigger;

    reg        date_test_rst = 1'b1;
    reg        date_test_day_tick = 1'b0;
    reg        date_test_edit = 1'b0;
    reg [1:0]  date_test_field = 2'd0;
    reg        date_test_add = 1'b0;
    wire [6:0] date_test_year;
    wire [3:0] date_test_month;
    wire [5:0] date_test_day;

    reg        countdown_test_rst = 1'b1;
    reg        countdown_test_enable = 1'b0;
    reg        countdown_test_edit = 1'b0;
    reg [1:0]  countdown_test_field = 2'd0;
    reg        countdown_test_add = 1'b0;
    reg        countdown_test_sub = 1'b0;
    wire [5:0] countdown_test_minute;
    wire [5:0] countdown_test_second;
    wire       countdown_test_finish;
    wire       countdown_test_led;

    reg        segment_test_rst = 1'b1;
    wire [7:0] segment_test_seg;
    wire [7:0] segment_test_dig;
    reg  [7:0] segment_seen = 8'h00;

    clock_top #(
        .CLOCKS_PER_SECOND(10), .DEBOUNCE_CYCLES(2), .DISPLAY_REFRESH_DIV(2),
        .DISPLAY_BLANK_CYCLES(2), .BLINK_DIV(4), .LED_HALF_PERIOD(2),
        .POWER_ON_RESET_CYCLES(4)
    ) dut (
        .clk(clk), .key(key), .sw(sw), .seg(seg), .dig(dig), .led_out(led_out)
    );

    // 独立闹钟实例，用于观察响铃、二次提醒和确认关闭过程。
    alarm alarm_master_enable_tb (
        .clk(clk), .rst(alarm_test_rst), .tick_1s(dut.tick_1s),
        .hour(6'd7), .minute(6'd0), .second(6'd0),
        .alarm_enable(alarm_test_enable), .edit_enable(1'b0),
        .edit_field(2'd0), .add(1'b0), .sub(1'b0),
        .alarm_select(2'd0), .acknowledge(alarm_test_ack),
        .alarm_hour0(), .alarm_minute0(), .alarm_hour1(), .alarm_minute1(),
        .alarm_hour2(), .alarm_minute2(), .alarm_trigger(alarm_test_trigger)
    );

    date_counter date_rollover_tb (
        .clk(clk), .rst(date_test_rst), .day_tick(date_test_day_tick),
        .edit_enable(date_test_edit), .edit_field(date_test_field),
        .add(date_test_add), .sub(1'b0), .year(date_test_year),
        .month(date_test_month), .day(date_test_day)
    );

    countdown countdown_finish_tb (
        .clk(clk), .rst(countdown_test_rst), .tick_1s(dut.tick_1s),
        .countdown_enable(countdown_test_enable), .edit_enable(countdown_test_edit),
        .edit_field(countdown_test_field), .add(countdown_test_add),
        .sub(countdown_test_sub), .minute(countdown_test_minute),
        .second(countdown_test_second), .countdown_finish(countdown_test_finish)
    );

    led #(.HALF_PERIOD_CYCLES(2)) countdown_led_tb (
        .clk(clk), .rst(countdown_test_rst), .trigger(countdown_test_finish),
        .led_out(countdown_test_led)
    );

    digital_tube #(.REFRESH_DIV(1), .BLINK_DIV(100), .BLANK_CYCLES(1)) segment_tb (
        .clk(clk), .rst(segment_test_rst), .display_data(32'h0123_4567),
        .blink_mask(8'h00), .seg(segment_test_seg), .dig(segment_test_dig)
    );

    always #5 clk = ~clk;

    // 依次显示 0～7，供波形窗口观察低有效段码与位选关系。
    always @(negedge clk) begin
        if (!segment_test_rst && (segment_test_dig !== 8'hff)) begin
            case (segment_test_dig)
                8'hfe: begin
                    segment_seen[0] <= 1'b1;
                end
                8'hfd: begin
                    segment_seen[1] <= 1'b1;
                end
                8'hfb: begin
                    segment_seen[2] <= 1'b1;
                end
                8'hf7: begin
                    segment_seen[3] <= 1'b1;
                end
                8'hef: begin
                    segment_seen[4] <= 1'b1;
                end
                8'hdf: begin
                    segment_seen[5] <= 1'b1;
                end
                8'hbf: begin
                    segment_seen[6] <= 1'b1;
                end
                8'h7f: begin
                    segment_seen[7] <= 1'b1;
                end
                default: ;
            endcase
        end
    end

    task wait_seconds;
        input integer seconds;
        integer i;
        begin
            for (i = 0; i < seconds; i = i + 1) begin
                @(posedge dut.tick_1s);
                @(posedge clk);
                #1;
            end
        end
    endtask

    task date_add_times;
        input [1:0] field;
        input integer times;
        integer i;
        begin
            date_test_edit  = 1'b1;
            date_test_field = field;
            for (i = 0; i < times; i = i + 1) begin
                @(negedge clk);
                date_test_add = 1'b1;
                @(posedge clk);
                @(negedge clk);
                date_test_add = 1'b0;
                @(posedge clk);
            end
        end
    endtask

    task date_pulse_day_tick;
        begin
            @(negedge clk);
            date_test_day_tick = 1'b1;
            @(posedge clk);
            @(negedge clk);
            date_test_day_tick = 1'b0;
            @(posedge clk);
        end
    endtask

    initial begin
        repeat (8) @(posedge clk);

        // 数码管动态扫描：独立实例依次显示 0～7。
        segment_test_rst = 1'b0;
        repeat (20) @(negedge clk);
        $stop;

        // 日期自动进位：1 月 31 日进入 2 月 1 日。
        date_test_rst = 1'b0;
        date_add_times(2'd2, 30);
        date_test_edit = 1'b0;
        date_pulse_day_tick;
        $stop;

        // 闰年日期自动进位：2028 年 2 月 29 日进入 3 月 1 日。
        date_test_rst = 1'b1;
        @(posedge clk);
        #1;
        date_test_rst = 1'b0;
        date_add_times(2'd0, 2);
        date_add_times(2'd1, 1);
        date_add_times(2'd2, 28);
        date_test_edit = 1'b0;
        date_pulse_day_tick;
        $stop;

        // 倒计时归零后保持完成提示约 5 秒，LED 在提示期间翻转。
        countdown_test_rst = 1'b0;
        countdown_test_edit = 1'b1;
        countdown_test_field = 2'd0;
        @(negedge clk);
        countdown_test_sub = 1'b1;
        @(posedge clk);
        @(negedge clk);
        countdown_test_sub = 1'b0;
        @(posedge clk);
        countdown_test_field = 2'd1;
        @(negedge clk);
        countdown_test_add = 1'b1;
        @(posedge clk);
        @(negedge clk);
        countdown_test_add = 1'b0;
        @(posedge clk);
        countdown_test_edit = 1'b0;
        countdown_test_enable = 1'b1;
        wait_seconds(1);
        repeat (2) @(posedge clk);
        #1;
        wait_seconds(4);
        wait_seconds(1);
        countdown_test_enable = 1'b0;
        $stop;

        // 闹钟首次响铃结束后等待 10 秒，再次响铃；确认后停止。
        alarm_test_rst = 1'b0;
        alarm_test_enable = 1'b1;
        wait_seconds(1);
        wait_seconds(5);
        wait_seconds(10);
        alarm_test_ack = 1'b1;
        @(posedge clk);
        #1;
        alarm_test_ack = 1'b0;
        $stop;
        $finish;
    end
endmodule
