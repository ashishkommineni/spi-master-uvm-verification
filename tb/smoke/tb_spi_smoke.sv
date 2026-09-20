`timescale 1ns / 1ps
module tb_spi_smoke;
  localparam int DATA_WIDTH = 8, NUM_CS = 4, CLK_DIV = 2;
  logic clk, rst_n, start, cpol, cpha, busy, done, sclk, mosi, miso;
  logic [1:0] cs_sel;
  logic [7:0] tx_data, rx_data;
  logic [3:0] cs_n;
  int checks = 0;
  initial clk = 0;
  always #5 clk = ~clk;
  assign miso = mosi;
  spi_master #(
      .DATA_WIDTH(DATA_WIDTH),
      .NUM_CS(NUM_CS),
      .CLK_DIV(CLK_DIV)
  ) dut (
      .*
  );
  task automatic transfer(input logic [1:0] mode, input logic [1:0] cs, input logic [7:0] data);
    while (busy) @(posedge clk);
    @(negedge clk);
    cpol = mode[1];
    cpha = mode[0];
    cs_sel = cs;
    tx_data = data;
    start = 1;
    @(negedge clk);
    start = 0;
    @(posedge done);
    #1;
    if (rx_data !== data) $fatal(1, "mode=%0d cs=%0d tx=%02h rx=%02h", mode, cs, data, rx_data);
    if (cs_n != '1 || sclk !== cpol) $fatal(1, "SPI did not return idle");
    checks++;
  endtask
  initial begin
    rst_n = 0;
    start = 0;
    cpol = 0;
    cpha = 0;
    cs_sel = 0;
    tx_data = 0;
    repeat (4) @(posedge clk);
    rst_n = 1;
    for (int m = 0; m < 4; m++)
    for (int c = 0; c < 4; c++) transfer(2'(m), 2'(c), DATA_WIDTH'(8'h81 ^ (m << 4) ^ c));
    $display("SPI_SMOKE_PASS checks=%0d", checks);
    $finish;
  end
endmodule
