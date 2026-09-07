`timescale 1ns / 1ps
// Smoke test: shortened divider/debounce values make one simulated second
// take ten clock edges.  Open the waveform to inspect display and LED scans.
module clock_tb;
    reg clk = 1'b0;
    reg [3:0] key = 4'b1111;
    reg [3:0] sw  = 4'b0000;
    wire [7:0] seg, dig;
    wire led_out;

    reg  alarm_test_rst = 1'b1;
    reg  alarm_test_enable = 1'b0;
    wire alarm_test_trigger;

    clock_top #(
        .CLOCKS_PER_SECOND(10), .DEBOUNCE_CYCLES(2), .DISPLAY_REFRESH_DIV(2),
        .DISPLAY_BLANK_CYCLES(2), .BLINK_DIV(4), .LED_HALF_PERIOD(2),
        .POWER_ON_RESET_CYCLES(4)
    ) dut (
        .clk(clk), .key(key), .sw(sw), .seg(seg), .dig(dig), .led_out(led_out)
    );

    // Isolated check that SW1's master-enable semantics silence an alarm
    // already in its ringing state.
    alarm alarm_master_enable_tb (
        .clk(clk), .rst(alarm_test_rst), .tick_1s(dut.tick_1s),
        .hour(6'd7), .minute(6'd0), .second(6'd0),
        .alarm_enable(alarm_test_enable), .edit_enable(1'b0),
        .edit_field(2'd0), .add(1'b0), .sub(1'b0),
        .alarm_select(2'd0), .acknowledge(1'b0),
        .alarm_hour0(), .alarm_minute0(), .alarm_hour1(), .alarm_minute1(),
        .alarm_hour2(), .alarm_minute2(), .alarm_trigger(alarm_test_trigger)
    );

    always #5 clk = ~clk;

    function is_one_cold;
        input [7:0] value;
        begin
            case (value)
                8'hfe, 8'hfd, 8'hfb, 8'hf7,
                8'hef, 8'hdf, 8'hbf, 8'h7f: is_one_cold = 1'b1;
                default:                       is_one_cold = 1'b0;
            endcase
        end
    endfunction

    // Board-level display contract: SEL is active-low, and digit changes
    // must pass through an all-off state so that segment patterns cannot
    // overlap on the PNP digit drivers.
    reg [7:0] previous_dig = 8'hff;
    always @(negedge clk) begin
        if (dut.power_on_done) begin
            if ((dig !== 8'hff) && !is_one_cold(dig))
                $fatal(1, "Digit select is not one-cold: dig=%02h", dig);
            if ((previous_dig !== 8'hff) && (dig !== 8'hff) &&
                (previous_dig !== dig))
                $fatal(1, "Digit select changed without an all-off interval");
        end
        previous_dig <= dig;
    end

    task press_key;
        input integer index;
        begin
            key[index] = 1'b0;
            repeat (4) @(posedge clk);
            key[index] = 1'b1;
            repeat (4) @(posedge clk);
        end
    endtask

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

    initial begin
        repeat (8) @(posedge clk);

        // View mode KEY1 changes pages.
        press_key(0);
        if (dut.display_mode !== 2'd1)
            $fatal(1, "View-mode KEY1 failed to select the date page");

        // In edit mode KEY1 changes fields but must not change the page.
        sw[2] = 1'b1;
        repeat (2) @(posedge clk);
        if (dut.edit_field !== 2'd0)
            $fatal(1, "Entering edit mode did not select the first field");
        press_key(0);
        if ((dut.display_mode !== 2'd1) || (dut.edit_field !== 2'd1))
            $fatal(1, "Edit-mode KEY1 did not advance the date field");
        press_key(1);
        if (dut.month !== 4'd2)
            $fatal(1, "Date edit failed: expected month=2, got %0d", dut.month);
        press_key(3);
        if (dut.edit_field !== 2'd1)
            $fatal(1, "KEY4 changed a field while no alarm was active");
        sw[2] = 1'b0;

        // In the alarm view, KEY3 selects the next of the three alarm groups.
        press_key(0);
        if (dut.display_mode !== 2'd2)
            $fatal(1, "View-mode KEY1 failed to select the alarm page");
        press_key(2);
        if (dut.alarm_select !== 2'd1)
            $fatal(1, "Alarm group selection failed: expected group 2");
        sw[2] = 1'b1;
        press_key(0);
        if ((dut.display_mode !== 2'd2) || (dut.edit_field !== 2'd1))
            $fatal(1, "Alarm edit field selection failed");
        press_key(1);
        if (dut.alarm_minute1 !== 6'd1)
            $fatal(1, "Alarm minute edit failed: got %0d", dut.alarm_minute1);
        sw[2] = 1'b0;

        // Countdown runs in view mode and remains running while another page is edited.
        press_key(0);
        if (dut.display_mode !== 2'd3)
            $fatal(1, "View-mode KEY1 failed to select the countdown page");
        sw[1] = 1'b1;
        wait_seconds(1);
        if ((dut.countdown_minute !== 6'd0) || (dut.countdown_second !== 6'd59))
            $fatal(1, "Countdown failed: expected 00:59, got %0d:%0d", dut.countdown_minute, dut.countdown_second);
        sw[1] = 1'b0;
        press_key(0); // time page
        sw[2] = 1'b1;
        sw[1] = 1'b1;
        wait_seconds(1);
        if (dut.countdown_second !== 6'd58)
            $fatal(1, "Countdown paused while another page was edited");
        sw[2] = 1'b0;
        sw[1] = 1'b0;

        // SW4 makes KEY4 a global reset key.
        sw[3] = 1'b1;
        press_key(3);
        sw[3] = 1'b0;
        repeat (8) @(posedge clk);
        if ((dut.display_mode !== 2'd0) || (dut.hour !== 6'd0) ||
            (dut.minute !== 6'd0) || (dut.month !== 4'd1) ||
            (dut.countdown_minute !== 6'd1) || (dut.countdown_second !== 6'd0))
            $fatal(1, "SW4 + KEY4 global reset failed");

        alarm_test_rst = 1'b0;
        alarm_test_enable = 1'b1;
        wait_seconds(1);
        if (!alarm_test_trigger)
            $fatal(1, "Alarm did not trigger when its master switch was enabled");
        alarm_test_enable = 1'b0;
        @(posedge clk);
        #1;
        if (alarm_test_trigger)
            $fatal(1, "SW1 did not silence an already active alarm");

        $display("RTL smoke test PASSED");
        $finish;
    end
endmodule
