XRUN?=xrun
VERILATOR?=verilator-cli
TEST?=spi_test
SEED?=random
.PHONY: uvm regress lint smoke nyc-smoke clean
uvm:
	mkdir -p results
	$(XRUN) -64bit -sv -uvm -f sim/files.f -top tb_top +UVM_TESTNAME=$(TEST) -svseed $(SEED) -access +rwc -coverage all -covoverwrite -covworkdir results/xcelium_cov -l results/xrun_$(TEST).log
regress:
	@for seed in 5 19 43 73 109;do $(MAKE) uvm SEED=$$seed||exit 1;done
lint:
	$(VERILATOR) --lint-only --sv --timing -Wall -Wno-fatal rtl/spi_master.sv
smoke:
	rm -rf build/obj_spi;mkdir -p build
	$(VERILATOR) --binary --sv --timing --assert -Wall -Wno-fatal -Wno-SYNCASYNCNET --top-module tb_spi_smoke --Mdir build/obj_spi rtl/spi_master.sv tb/assertions/spi_sva.sv tb/smoke/tb_spi_smoke.sv
	bash -o pipefail -c './build/obj_spi/Vtb_spi_smoke | tee results_smoke.log'
nyc-smoke:
	rm -rf build/obj_nyc; mkdir -p build
	$(VERILATOR) --binary --sv --timing -Wall -Wno-fatal --top-module tb_nyc_digital_clock --Mdir build/obj_nyc rtl/nyc_digital_clock.sv tb/smoke/tb_nyc_digital_clock.sv
	bash -o pipefail -c './build/obj_nyc/Vtb_nyc_digital_clock | tee results_nyc_clock.log'
clean:
	rm -rf build xcelium.d INCA_libs waves.shm results *.log *.key
