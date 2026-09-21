`timescale 1ns/1ps
// Synthesizable UTC -> America/New_York clock.
// The UTC date/time is normally supplied by an RTC or time-synchronization block.
// DST follows the US rule: second Sunday in March through first Sunday in November.
module nyc_digital_clock #(
    parameter int unsigned CLK_HZ = 50_000_000,
    parameter int unsigned SCAN_HZ = 1_000
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [15:0] utc_year,
    input  logic [3:0]  utc_month,
    input  logic [5:0]  utc_day,
    input  logic [5:0]  utc_hour,
    input  logic [5:0]  utc_minute,
    input  logic [5:0]  utc_second,
    output logic [4:0]  local_hour,
    output logic [5:0]  local_minute,
    output logic [5:0]  local_second,
    output logic        daylight_time,
    output logic [3:0]  bcd_hour_tens,
    output logic [3:0]  bcd_hour_ones,
    output logic [3:0]  bcd_min_tens,
    output logic [3:0]  bcd_min_ones,
    output logic [3:0]  bcd_sec_tens,
    output logic [3:0]  bcd_sec_ones,
    output logic [5:0]  digit_en,
    output logic [6:0]  segments,
    output logic        edt_indicator
);
  localparam int unsigned SCAN_DIV = (CLK_HZ / (SCAN_HZ * 6)) < 1 ? 1 : (CLK_HZ / (SCAN_HZ * 6));
  localparam int unsigned SCAN_W = (SCAN_DIV <= 1) ? 1 : $clog2(SCAN_DIV);
  logic [SCAN_W-1:0] scan_count;
  logic [2:0] scan_digit;
  logic [3:0] scan_value;
  logic [4:0] adjusted_hour;
  logic [6:0] segment_value;

  function automatic logic leap(input int y);
    return ((y % 4) == 0 && (y % 100) != 0) || ((y % 400) == 0);
  endfunction

  // Gregorian day of week, with Sunday == 0.
  function automatic int day_of_week(input int y, input int m, input int d);
    int yy, mm;
    begin
      yy = y - ((m < 3) ? 1 : 0);
      mm = m + ((m < 3) ? 12 : 0);
      return (yy + yy/4 - yy/100 + yy/400 + (13*(mm+1))/5 + d) % 7;
    end
  endfunction

  function automatic int first_sunday(input int y, input int m);
    int first_dow;
    begin
      first_dow = day_of_week(y, m, 1);
      return 1 + ((7 - first_dow) % 7);
    end
  endfunction

  function automatic logic is_dst(
      input int y, input int m, input int d,
      input int h, input int mi, input int s);
    int start_day, end_day;
    begin
      start_day = first_sunday(y, 3) + 7; // second Sunday in March
      end_day   = first_sunday(y, 11);    // first Sunday in November
      if (m < 3 || m > 11) return (m > 3 && m < 11);
      if (m > 3 && m < 11) return 1'b1;
      if (m == 3) begin
        if (d > start_day) return 1'b1;
        if (d < start_day) return 1'b0;
        return (h > 7) || (h == 7 && (mi > 0 || s >= 0));
      end
      if (d < end_day) return 1'b1;
      if (d > end_day) return 1'b0;
      return (h < 6);
    end
  endfunction

  function automatic [6:0] seven_segment(input logic [3:0] value);
    // Active-low segments: {g,f,e,d,c,b,a}.
    case (value)
      4'd0: seven_segment = 7'b1000000;
      4'd1: seven_segment = 7'b1111001;
      4'd2: seven_segment = 7'b0100100;
      4'd3: seven_segment = 7'b0110000;
      4'd4: seven_segment = 7'b0011001;
      4'd5: seven_segment = 7'b0010010;
      4'd6: seven_segment = 7'b0000010;
      4'd7: seven_segment = 7'b1111000;
      4'd8: seven_segment = 7'b0000000;
      4'd9: seven_segment = 7'b0010000;
      default: seven_segment = 7'b1111111;
    endcase
  endfunction

  always_comb begin
    daylight_time = is_dst(utc_year, utc_month, utc_day, utc_hour, utc_minute, utc_second);
    adjusted_hour = utc_hour + (daylight_time ? 20 : 19); // modulo-24 form of -4/-5
    local_hour = adjusted_hour % 24;
    local_minute = utc_minute;
    local_second = utc_second;
    // Adding a negative whole-hour offset does not alter minutes/seconds.
    // The hour wrap above is valid for every UTC hour.
    bcd_hour_tens = local_hour / 10;
    bcd_hour_ones = local_hour % 10;
    bcd_min_tens = local_minute / 10;
    bcd_min_ones = local_minute % 10;
    bcd_sec_tens = local_second / 10;
    bcd_sec_ones = local_second % 10;
  end

  always_comb begin
    case (scan_digit)
      3'd0: begin scan_value = bcd_hour_tens; digit_en = 6'b011111; end
      3'd1: begin scan_value = bcd_hour_ones; digit_en = 6'b101111; end
      3'd2: begin scan_value = bcd_min_tens;  digit_en = 6'b110111; end
      3'd3: begin scan_value = bcd_min_ones;  digit_en = 6'b111011; end
      3'd4: begin scan_value = bcd_sec_tens;  digit_en = 6'b111101; end
      default: begin scan_value = bcd_sec_ones; digit_en = 6'b111110; end
    endcase
    segment_value = seven_segment(scan_value);
    segments = segment_value;
    edt_indicator = daylight_time;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      scan_count <= '0;
      scan_digit <= '0;
    end else if (scan_count == SCAN_DIV - 1) begin
      scan_count <= '0;
      scan_digit <= (scan_digit == 3'd5) ? 3'd0 : scan_digit + 1'b1;
    end else begin
      scan_count <= scan_count + 1'b1;
    end
  end
endmodule
