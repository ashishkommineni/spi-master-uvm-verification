# Verification Results

Revalidated: 2026-09-21

## Executed checks

| Check | Result | Evidence |
|---|---|---|
| RTL lint | PASS | `make lint`; zero RTL warnings |
| Executable loopback + SVA smoke | PASS | `SPI_SMOKE_PASS checks=16` |
| Parameter elaboration | PASS | 16-bit data, two targets, and `CLK_DIV=4` passed strict lint |
| UVM source compile/elaboration | PASS | Full hierarchy compiled against Accellera UVM `78c0654` |

```text
SPI_SMOKE_PASS checks=16
```

All 16 mode × chip-select combinations transfer a non-symmetric byte through the real MOSI/MISO datapath. The test checks returned data, one-hot selection, completion, deselection, and final clock polarity; SVA is instantiated in the executable.

## Second-pass findings corrected

- Explicit target and payload constraints were added to the random item.
- The receive shift register was reduced to the state actually needed, removing a real lint warning without suppressing it.
- Completion/idle assertions were made transaction-aware across a CPOL change.
- `pipefail` now propagates assertion failures; this audit demonstrated the old pipeline could hide one.

## Xcelium boundary

No Xcelium runtime or coverage percentage is claimed in this workspace. Complete UVM elaboration passed. Run `make regress` with the licensed simulator and require zero UVM errors/fatals, passing SVA, and all mode/target/payload bins.
