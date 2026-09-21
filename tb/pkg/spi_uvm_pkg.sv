`timescale 1ns / 1ps
package spi_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  localparam int DATA_WIDTH = 8, NUM_CS = 4, CLK_DIV = 2;
  class spi_item extends uvm_sequence_item;
    rand bit [DATA_WIDTH-1:0] data;
    rand bit cpol, cpha;
    rand bit [$clog2(NUM_CS)-1:0] cs;
    bit [DATA_WIDTH-1:0] rx_data;
    constraint c_target {cs inside {[0 : NUM_CS - 1]};}
    constraint c_payload {
      data dist {
        8'h00 := 1,
        8'hff := 1,
        8'h55 := 1,
        8'haa := 1,
        [8'h01 : 8'hfe] := 12
      };
    }
    `uvm_object_utils_begin(spi_item)
      `uvm_field_int(data, UVM_HEX)
      `uvm_field_int(cpol, UVM_DEFAULT)
      `uvm_field_int(cpha, UVM_DEFAULT)
      `uvm_field_int(cs, UVM_DEC)
      `uvm_field_int(rx_data, UVM_HEX)
    `uvm_object_utils_end
    function new(string name = "spi_item");
      super.new(name);
    endfunction
  endclass
  class spi_sequencer extends uvm_sequencer #(spi_item);
    `uvm_component_utils(spi_sequencer)
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
  endclass
  class spi_driver extends uvm_driver #(spi_item);
    `uvm_component_utils(spi_driver)
    virtual spi_if #(DATA_WIDTH, NUM_CS) vif;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual spi_if #(DATA_WIDTH, NUM_CS))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "spi_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      vif.drv_cb.start <= 0;
      vif.drv_cb.cpol <= 0;
      vif.drv_cb.cpha <= 0;
      vif.drv_cb.cs_sel <= '0;
      vif.drv_cb.tx_data <= '0;
      wait (vif.rst_n === 1);
      forever begin
        seq_item_port.get_next_item(req);
        while (vif.busy) @(vif.drv_cb);
        vif.drv_cb.cpol <= req.cpol;
        vif.drv_cb.cpha <= req.cpha;
        vif.drv_cb.cs_sel <= req.cs;
        vif.drv_cb.tx_data <= req.data;
        vif.drv_cb.start <= 1;
        @(vif.drv_cb);
        vif.drv_cb.start <= 0;
        seq_item_port.item_done();
      end
    endtask
  endclass
  class spi_monitor extends uvm_monitor;
    `uvm_component_utils(spi_monitor)
    virtual spi_if #(DATA_WIDTH, NUM_CS) vif;
    uvm_analysis_port #(spi_item) ap;
    function new(string n, uvm_component p);
      super.new(n, p);
      ap = new("ap", this);
    endfunction
    function void build_phase(uvm_phase phase);
      if (!uvm_config_db#(virtual spi_if #(DATA_WIDTH, NUM_CS))::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "spi_if missing")
    endfunction
    task run_phase(uvm_phase phase);
      spi_item tr;
      wait (vif.rst_n === 1);
      forever begin
        @(posedge vif.clk iff (vif.start && !vif.busy));
        tr = spi_item::type_id::create("tr");
        tr.data = vif.tx_data;
        tr.cpol = vif.cpol;
        tr.cpha = vif.cpha;
        tr.cs = vif.cs_sel;
        @(posedge vif.clk iff vif.done);
        #1ps;
        tr.rx_data = vif.rx_data;
        ap.write(tr);
      end
    endtask
  endclass
  class spi_agent extends uvm_agent;
    `uvm_component_utils(spi_agent)
    spi_sequencer sqr;
    spi_driver drv;
    spi_monitor mon;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      sqr = spi_sequencer::type_id::create("sqr", this);
      drv = spi_driver::type_id::create("drv", this);
      mon = spi_monitor::type_id::create("mon", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      drv.seq_item_port.connect(sqr.seq_item_export);
    endfunction
  endclass
  class spi_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(spi_scoreboard)
    uvm_analysis_imp #(spi_item, spi_scoreboard) analysis_export;
    int checked;
    function new(string n, uvm_component p);
      super.new(n, p);
      analysis_export = new("analysis_export", this);
    endfunction
    function void write(spi_item tr);
      checked++;
      if (tr.rx_data !== tr.data)
        `uvm_error("LOOPBACK", $sformatf(
                   "mode=%0d tx=%02h rx=%02h", {tr.cpol, tr.cpha}, tr.data, tr.rx_data))
    endfunction
    function void check_phase(uvm_phase phase);
      if (checked == 0) `uvm_error("NO_TRAFFIC", "No SPI transfers reached the scoreboard")
    endfunction
    function void report_phase(uvm_phase phase);
      `uvm_info("SPI_SUMMARY", $sformatf("Checked %0d transfers", checked), UVM_LOW)
    endfunction
  endclass
  class spi_coverage extends uvm_subscriber #(spi_item);
    `uvm_component_utils(spi_coverage)
    spi_item tr;
    covergroup cg;
      cp_mode: coverpoint {tr.cpol, tr.cpha} {bins modes[] = {0, 1, 2, 3};}
      cp_cs: coverpoint tr.cs;
      cp_data: coverpoint tr.data {
        bins zero = {0}; bins ones = {'1}; bins alt[] = {8'h55, 8'haa}; bins other = default;
      }
      cx: cross cp_mode, cp_cs;
    endgroup
    function new(string n, uvm_component p);
      super.new(n, p);
      cg = new();
    endfunction
    function void write(spi_item t);
      tr = t;
      cg.sample();
    endfunction
  endclass
  class spi_env extends uvm_env;
    `uvm_component_utils(spi_env)
    spi_agent agent;
    spi_scoreboard sb;
    spi_coverage cov;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      agent = spi_agent::type_id::create("agent", this);
      sb = spi_scoreboard::type_id::create("sb", this);
      cov = spi_coverage::type_id::create("cov", this);
    endfunction
    function void connect_phase(uvm_phase phase);
      agent.mon.ap.connect(sb.analysis_export);
      agent.mon.ap.connect(cov.analysis_export);
    endfunction
  endclass
  class spi_sequence extends uvm_sequence #(spi_item);
    `uvm_object_utils(spi_sequence)
    function new(string n = "spi_sequence");
      super.new(n);
    endfunction
    task body();
      for (int mode = 0; mode < 4; mode++)
        for (int cs = 0; cs < NUM_CS; cs++) begin
          req = spi_item::type_id::create("directed");
          start_item(req);
          req.cpol = mode[1];
          req.cpha = mode[0];
          req.cs   = cs;
          req.data = 8'h96 ^ (mode << 4) ^ cs;
          finish_item(req);
        end
      repeat (48) begin
        req = spi_item::type_id::create("random");
        start_item(req);
        if (!req.randomize()) `uvm_fatal("RAND", "randomization failed")
        finish_item(req);
      end
    endtask
  endclass
  class spi_test extends uvm_test;
    `uvm_component_utils(spi_test)
    spi_env env;
    function new(string n, uvm_component p);
      super.new(n, p);
    endfunction
    function void build_phase(uvm_phase phase);
      env = spi_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
      spi_sequence seq;
      phase.raise_objection(this);
      seq = spi_sequence::type_id::create("seq");
      seq.start(env.agent.sqr);
      wait (!env.agent.mon.vif.busy);
      repeat (4) @(posedge env.agent.mon.vif.clk);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
