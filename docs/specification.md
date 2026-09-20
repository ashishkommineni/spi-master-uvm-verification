# SPI Master Specification

The master performs fixed-width, MSB-first, full-duplex transfers. It supports all four CPOL/CPHA modes and one-hot active-low selection of four slaves. `CLK_DIV` system-clock cycles form each SCLK half period.

| Mode | CPOL | CPHA | Sample edge | Change edge |
|---:|---:|---:|---|---|
| 0 | 0 | 0 | Rising | Falling |
| 1 | 0 | 1 | Falling | Rising |
| 2 | 1 | 0 | Falling | Rising |
| 3 | 1 | 1 | Rising | Falling |

`start` is accepted only while idle. The selected `cs_n` remains asserted across the complete word. `done` pulses for one system-clock cycle after the final sample and SCLK returns to its CPOL idle level.
