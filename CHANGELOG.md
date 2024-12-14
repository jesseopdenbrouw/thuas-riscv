## Project Change Log

This is the project changelog starting from version 1.0.0.0.
Prior versions are not documented here.
The current hardware version is available in the `mimpid` CSR as a four-number string (BCD encoded),

As an example, see below:

```
mimpid = 0x01040312 -> Version 01.04.03.12 -> v1.4.3.12
```

All dates are in dd.mm.yyyy format.

| Date       | Version  | Comment | Issue |
|:----------:|:--------:|:--------|:-----:|
| 13.08.2024 | 1.0.0.0  | Based on version 0.9.10.1 + on-chip debugging | |
| 29.08.2024 | 1.0.0.1  | tdo = tdi when OCD is disabled, minor change in multipliers | |
| 04.09.2024 | 1.0.0.2  | Some minor changes, no real hardware changes | |
| 07.09.2024 | 1.0.1.0  | [dm] Added auto-increment on memory accesses | |
| 09.09.2024 | 1.0.1.1  | [dm] Fix bug in auto-increment calculation | |
| 17.09.2024 | 1.0.1.2  | Removed unused signal | |
| 21.09.2024 | 1.0.1.3  | Minor comment edits, moved a signal in core | |
| 27.09.2024 | 1.0.1.4  | MEPC has bit 0 set to hard 0, PC witg JARL has bit 0 set to hard 0 | |
| 30.09.2024 | 1.0.1.5  | [core] fixed handling of NMI | |
| 04.10.2024 | 1.0.2.0  | New version |
| 19.10.2024 | 1.0.2.1  | [bootloader] Removed unused variable, renamed all variables to ending with v. [common] update function initialize_memory | |
| 22.10.2024 | 1.0.2.2  | [io] SPI1 MOSI default to 1 | |
| 28.10.2024 | 1.0.2.3  | [core] rework memory access hardware | |
| 30.10.2024 | 1.0.3.0  | New release (has wrong version number) | |
| 11.11.2024 | 1.0.4.0  | New release. [io] Removed hardware CS (NSS) from SPI1 because of limited usability. SPI2 now has interrupt (SPI1 and SPI2 are identical), fixed parity issues in UART1, minor edits. | |
| 14.11.2024 | 1.0.4.1  | [io] Removed unused flipflops in I2C1 and I2C2 | |
| 08.12.2024 | 1.0.5.0  | New release. [docs] new schematic of SoC | |
| 14.12.2024 | 1.1.0.0  | New version. Complete rewrite of the I/O sub-system | |
| 23.11.2924 | 1.0.4.2  | [riscv] Added synchronized reset for DM and DTM, [io] removed some unused memory. | |
| 08.12.2024 | 1.0.5.0  | New release. [docs] new schematic of SoC | |
| 14.12.2024 | 1.1.0.0  | New release. Completely new I/O sub-system | |
