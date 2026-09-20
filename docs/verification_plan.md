# Verification Plan

Directed testing crosses all four SPI modes with all four chip selects. Random traffic varies modes, selections, and payloads. The loopback slave path (`MISO=MOSI`) gives an exact full-duplex data oracle. The scoreboard compares each completed word; coverage classifies modes, chip selects, boundary patterns, and mode × select combinations. Assertions check one-hot selection, idle deselection, idle polarity, and one-cycle completion.
