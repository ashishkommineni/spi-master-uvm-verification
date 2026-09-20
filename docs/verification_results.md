# Verification results

Validation date: 2026-09-20

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint` completed with Verilator |
| Executable RTL smoke test | PASS | `SPI_SMOKE_PASS checks=16` |
| UVM source compile/elaboration lint | PASS | `sim/files.f`, assertions, and UVM package compiled against Accellera UVM core commit `78c0654` |

The smoke test performs 16 full-duplex loopback transfers spanning CPOL/CPHA modes 0–3 and all four chip selects, while checking returned data, `done`, and idle clock polarity.

## Xcelium status

Cadence Xcelium was not installed in the validation environment, so no Xcelium runtime result is claimed. On a licensed Xcelium host, run `make uvm` for one seeded test or `make regress` for the five-seed regression. A passing run must finish with zero `UVM_ERROR` and zero `UVM_FATAL` messages.
