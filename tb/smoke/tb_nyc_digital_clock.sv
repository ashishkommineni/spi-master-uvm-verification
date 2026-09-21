`timescale 1ns/1ps
module tb_nyc_digital_clock;
  logic clk = 0, rst_n = 0;
  always #5 clk = ~clk;
  logic [15:0] year;
  logic [3:0] month;
  logic [5:0] day, hour, minute, second;
  logic [4:0] local_hour;
  logic [5:0] local_minute, local_second;
  logic dst;
  logic [3:0] ht, ho, mt, mo, st, so;
  logic [5:0] digit_en;
  logic [6:0] segments;
  logic edt_indicator;

  nyc_digital_clock #(.CLK_HZ(100), .SCAN_HZ(1)) dut (
    .clk, .rst_n, .utc_year(year), .utc_month(month), .utc_day(day),
    .utc_hour(hour), .utc_minute(minute), .utc_second(second),
    .local_hour, .local_minute, .local_second, .daylight_time(dst),
    .bcd_hour_tens(ht), .bcd_hour_ones(ho), .bcd_min_tens(mt),
    .bcd_min_ones(mo), .bcd_sec_tens(st), .bcd_sec_ones(so),
    .digit_en, .segments, .edt_indicator
  );

  task automatic check(input int exp_hour, input logic exp_dst, input string label);
    #1;
    if (local_hour !== exp_hour || dst !== exp_dst)
      $fatal(1, "%s: hour=%0d dst=%0d", label, local_hour, dst);
    $display("NYC_CLOCK_PASS %s local=%02d:%02d:%02d %s",
             label, local_hour, local_minute, local_second,
             dst ? "EDT" : "EST");
  endtask

  initial begin
    year=2026; month=3; day=8; hour=6; minute=59; second=59;
    repeat (2) @(posedge clk); rst_n = 1;
    check(1, 0, "before spring transition");
    hour=7; minute=0; second=0; check(3, 1, "after spring transition");
    month=7; day=4; hour=16; minute=30; second=0; check(12, 1, "summer");
    month=11; day=1; hour=5; minute=59; second=59; check(1, 1, "before fall transition");
    hour=6; minute=0; second=0; check(1, 0, "after fall transition");
    month=1; day=1; hour=12; minute=0; second=0; check(7, 0, "winter");
    $finish;
  end
endmodule
