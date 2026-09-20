`timescale 1ns / 1ps
module spi_sva #(
    parameter int NUM_CS = 4
) (
    input logic clk,
    rst_n,
    busy,
    done,
    sclk,
    cpol,
    input logic [NUM_CS-1:0] cs_n
);
  default clocking cb @(posedge clk);
  endclocking
  default disable iff (!rst_n); ap_one_cs :
  assert property (busy |-> $onehot(~cs_n));
  ap_idle_cs :
  assert property (!busy |-> cs_n == '1);
  ap_idle_clock :
  assert property (!busy |-> sclk == cpol);
  ap_done_pulse :
  assert property (done |=> !done);
  cp_transfer :
  cover property ($rose(busy) ##[1:200] done);
endmodule
