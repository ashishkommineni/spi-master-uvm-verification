`timescale 1ns / 1ps

module spi_master #(
    parameter  int unsigned DATA_WIDTH = 8,
    parameter  int unsigned NUM_CS     = 4,
    parameter  int unsigned CLK_DIV    = 2,
    localparam int unsigned CS_W       = $clog2(NUM_CS),
    localparam int unsigned DIV_W      = $clog2(CLK_DIV),
    localparam int unsigned COUNT_W    = $clog2(DATA_WIDTH + 1)
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  start,
    input  logic                  cpol,
    input  logic                  cpha,
    input  logic [      CS_W-1:0] cs_sel,
    input  logic [DATA_WIDTH-1:0] tx_data,
    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy,
    output logic                  done,
    output logic                  sclk,
    output logic                  mosi,
    input  logic                  miso,
    output logic [    NUM_CS-1:0] cs_n
);

  initial begin
    if (DATA_WIDTH < 2) $fatal(1, "DATA_WIDTH must be at least 2");
    if (NUM_CS < 1 || (NUM_CS & (NUM_CS - 1)) != 0) $fatal(1, "NUM_CS must be a power of two");
    if (CLK_DIV < 2) $fatal(1, "CLK_DIV must be at least 2");
  end

  localparam logic [DIV_W-1:0] LAST_DIV = DIV_W'(CLK_DIV - 1);
  localparam logic [COUNT_W-1:0] LAST_SAMPLE = COUNT_W'(DATA_WIDTH - 1);

  logic [     DIV_W-1:0] div_count_q;
  logic [   COUNT_W-1:0] sample_count_q;
  logic [DATA_WIDTH-1:0] tx_shift_q;
  logic [DATA_WIDTH-1:0] rx_shift_q;
  logic                  finish_pending_q;
  logic                  leading_edge;
  logic                  sample_edge;
  logic                  shift_edge;

  always_comb begin
    leading_edge = (sclk == cpol);
    sample_edge  = (!cpha && leading_edge) || (cpha && !leading_edge);
    shift_edge   = !sample_edge;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      div_count_q      <= '0;
      sample_count_q   <= '0;
      tx_shift_q       <= '0;
      rx_shift_q       <= '0;
      finish_pending_q <= 1'b0;
      rx_data          <= '0;
      busy             <= 1'b0;
      done             <= 1'b0;
      sclk             <= 1'b0;
      mosi             <= 1'b0;
      cs_n             <= '1;
    end else begin
      done <= 1'b0;

      if (!busy) begin
        div_count_q <= '0;
        sclk        <= cpol;
        cs_n        <= '1;
        mosi        <= 1'b0;
        if (start) begin
          busy             <= 1'b1;
          cs_n[cs_sel]     <= 1'b0;
          sample_count_q   <= '0;
          tx_shift_q       <= tx_data;
          rx_shift_q       <= '0;
          finish_pending_q <= 1'b0;
          if (!cpha) mosi <= tx_data[DATA_WIDTH-1];
        end
      end else if (div_count_q == LAST_DIV) begin
        div_count_q <= '0;

        // CPHA=0 completes one trailing edge after its final leading sample.
        if (finish_pending_q) begin
          sclk             <= cpol;
          cs_n             <= '1;
          busy             <= 1'b0;
          done             <= 1'b1;
          finish_pending_q <= 1'b0;
          mosi             <= 1'b0;
        end else begin
          sclk <= ~sclk;

          if (shift_edge) begin
            if (cpha) begin
              mosi       <= tx_shift_q[DATA_WIDTH-1];
              tx_shift_q <= {tx_shift_q[DATA_WIDTH-2:0], 1'b0};
            end else begin
              mosi       <= tx_shift_q[DATA_WIDTH-2];
              tx_shift_q <= {tx_shift_q[DATA_WIDTH-2:0], 1'b0};
            end
          end

          if (sample_edge) begin
            rx_shift_q <= {rx_shift_q[DATA_WIDTH-2:0], miso};
            if (sample_count_q == LAST_SAMPLE) begin
              rx_data <= {rx_shift_q[DATA_WIDTH-2:0], miso};
              if (cpha) begin
                // CPHA=1 samples on the trailing edge, which already returns SCLK to idle.
                sclk <= cpol;
                cs_n <= '1;
                busy <= 1'b0;
                done <= 1'b1;
                mosi <= 1'b0;
              end else begin
                finish_pending_q <= 1'b1;
              end
            end else sample_count_q <= sample_count_q + 1'b1;
          end
        end
      end else begin
        div_count_q <= div_count_q + 1'b1;
      end
    end
  end
endmodule
