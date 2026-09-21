# SPI Master Specification

## Interface contract

The master transfers one `DATA_WIDTH`-bit word, MSB first, using one of `NUM_CS` active-low chip selects. `NUM_CS` is a power of two, `DATA_WIDTH` is at least two, and `CLK_DIV` is at least two.

A one-cycle `start` while idle latches the payload and selected target and raises `busy`. Requests received while busy are ignored. Exactly one `cs_n` bit is low during a transfer. `rx_data` is updated after the last sample, `done` pulses for one clock, and SCLK returns to its idle polarity.

## Mode timing

| Mode | CPOL | CPHA | Idle clock | Sample edge | Shift edge |
|---:|---:|---:|---|---|---|
| 0 | 0 | 0 | Low | Leading/rising | Trailing/falling |
| 1 | 0 | 1 | Low | Trailing/falling | Leading/rising |
| 2 | 1 | 0 | High | Leading/falling | Trailing/rising |
| 3 | 1 | 1 | High | Trailing/rising | Leading/falling |

For CPHA=0, the first MOSI bit is available before the first active edge. For CPHA=1, the first active edge launches it. MISO is sampled on the mode-selected sample edge, so transmit and receive proceed simultaneously.

## Reset and boundaries

Active-low asynchronous reset deselects every target, clears data state, and drives SCLK low until the next idle configuration is observed. This compact controller does not provide variable word lengths per transaction, LSB-first operation, multi-word CS hold, three-wire direction control, or per-target clock dividers.
