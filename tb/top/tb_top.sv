`timescale 1ns / 1ps
module tb_top;
  import uvm_pkg::*;
  import spi_uvm_pkg::*;
  logic clk = 0;
  always #5ns clk = ~clk;
  spi_if #(DATA_WIDTH, NUM_CS) vif (clk);
  assign vif.miso = vif.mosi;
  spi_master #(
      .DATA_WIDTH(DATA_WIDTH),
      .NUM_CS(NUM_CS),
      .CLK_DIV(CLK_DIV)
  ) dut (
      .clk,
      .rst_n(vif.rst_n),
      .start(vif.start),
      .cpol(vif.cpol),
      .cpha(vif.cpha),
      .cs_sel(vif.cs_sel),
      .tx_data(vif.tx_data),
      .rx_data(vif.rx_data),
      .busy(vif.busy),
      .done(vif.done),
      .sclk(vif.sclk),
      .mosi(vif.mosi),
      .miso(vif.miso),
      .cs_n(vif.cs_n)
  );
  spi_sva #(
      .NUM_CS(NUM_CS)
  ) sva (
      .clk,
      .rst_n(vif.rst_n),
      .busy (vif.busy),
      .done (vif.done),
      .sclk (vif.sclk),
      .cpol (vif.cpol),
      .cs_n (vif.cs_n)
  );
  initial begin
    vif.rst_n = 0;
    vif.start = 0;
    vif.cpol = 0;
    vif.cpha = 0;
    vif.cs_sel = 0;
    vif.tx_data = '0;
    repeat (4) @(posedge clk);
    vif.rst_n = 1;
  end
  initial begin
    uvm_config_db#(virtual spi_if #(DATA_WIDTH, NUM_CS))::set(null, "uvm_test_top.env.agent.*",
                                                              "vif", vif);
    run_test("spi_test");
  end
endmodule
