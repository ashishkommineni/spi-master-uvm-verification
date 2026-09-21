# SPI Master RTL and UVM Verification

A synthesizable SPI master supporting modes 0–3, four chip selects, configurable clock division, UVM verification, SVA, coverage, and an executable Verilator loopback test.

## Key behavior

- Full-duplex, MSB-first transfers
- CPOL/CPHA modes 0, 1, 2, and 3
- One-hot active-low chip selection
- Registered receive word and one-cycle `done`
- SCLK returns to its configured idle polarity after every transfer

See [the protocol contract](docs/specification.md) and [verification plan](docs/verification_plan.md).

## Run

```bash
make uvm       # Cadence Xcelium/UVM
make regress   # five random seeds
make lint      # Verilator RTL lint
make smoke     # 16 real loopback transfers
```

Successful portable execution runs the SVA and prints `SPI_SMOKE_PASS checks=16`. The Xcelium test adds constrained-random mode/data/select combinations and reports `SPI_SUMMARY` with zero UVM errors.

See [verified results and tool scope](docs/verification_results.md) for the reproducible validation record.

## Verification insight

The first data bit is preloaded for CPHA=0 because the receiver samples on the first clock edge. For CPHA=1, the first edge changes data and the second edge samples it. Handling that distinction—and returning the clock to CPOL after the final bit—is the central timing problem in a mode-independent SPI master.

## License

MIT — see [LICENSE](LICENSE).
