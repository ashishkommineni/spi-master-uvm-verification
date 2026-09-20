`timescale 1ns / 1ps
interface spi_if #(
    parameter int DATA_WIDTH = 8,
    NUM_CS = 4
) (
    input logic clk
);
  localparam int CS_W = $clog2(NUM_CS);
  logic rst_n, start, cpol, cpha;
  logic [CS_W-1:0] cs_sel;
  logic [DATA_WIDTH-1:0] tx_data, rx_data;
  logic busy, done, sclk, mosi, miso;
  logic [NUM_CS-1:0] cs_n;
  clocking drv_cb @(negedge clk);
    output start, cpol, cpha, cs_sel, tx_data;
    input busy, done, rx_data, sclk, mosi, cs_n;
  endclocking
endinterface
