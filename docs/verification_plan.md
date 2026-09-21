# Verification Plan

## Strategy

The environment uses a pin-level full-duplex loopback (`MISO=MOSI`). This is intentionally simple but exact: every sampled receive word must equal the transmitted word regardless of clock mode or selected target. The monitor observes accepted `start`, waits for `done`, and sends the completed transfer to both scoreboard and coverage.

| Goal | Stimulus | Check |
|---|---|---|
| Four clock modes | Directed modes 0–3 | Loopback data and idle-polarity checks |
| Target selection | Every mode × all four chip selects | One-hot active-low SVA and cross coverage |
| Bit ordering | Non-symmetric payloads plus random data | Exact TX/RX scoreboard |
| Boundary payloads | Weighted `00`, `FF`, `55`, `AA` | Dedicated coverage bins |
| Completion | All directed/random transfers | One-cycle `done`, idle CS/SCLK assertions |

## Constraints and coverage

`cs` is constrained to the implemented target range. Payload weighting regularly selects boundary and alternating patterns without eliminating the rest of the byte space. CPOL and CPHA remain free, producing all modes. Coverage records mode, selected target, payload class, and mode × target.

## Assertions and closure

While busy, exactly one chip select must be active. While idle, all targets must be deselected and SCLK must match CPOL once no new start is being accepted. Completion must be a one-cycle pulse and return BUSY/CS/SCLK to the previous transaction's idle state. Closure requires zero UVM errors/fatals, passing SVA, the planned bins, and all 16 portable directed transfers passing.
