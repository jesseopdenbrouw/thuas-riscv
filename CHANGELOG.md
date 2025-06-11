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
| 27.09.2024 | 1.0.1.4  | MEPC has bit 0 set to hard 0, PC with JARL has bit 0 set to hard 0 | |
| 30.09.2024 | 1.0.1.5  | [core] fixed handling of NMI | |
| 04.10.2024 | 1.0.2.0  | New version |
| 19.10.2024 | 1.0.2.1  | [bootloader] Removed unused variable, renamed all variables to ending with v. [common] update function initialize_memory | |
| 22.10.2024 | 1.0.2.2  | [io] SPI1 MOSI default to 1 | |
| 28.10.2024 | 1.0.2.3  | [core] rework memory access hardware | |
| 30.10.2024 | 1.0.3.0  | New release (has wrong version number) | |
| 11.11.2024 | 1.0.4.0  | New release. [io] Removed hardware CS (NSS) from SPI1 because of limited usability. SPI2 now has interrupt (SPI1 and SPI2 are identical), fixed parity issues in UART1, minor edits. | |
| 14.11.2024 | 1.0.4.1  | [io] Removed unused flipflops in I2C1 and I2C2 | |
| 23.11.2924 | 1.0.4.2  | [riscv] Added synchronized reset for DM and DTM, [io] removed some unused memory. | |
| 08.12.2024 | 1.0.5.0  | New release. [docs] new schematic of SoC | |
| 14.12.2024 | 1.1.0.0  | New release. Completely new I/O sub-system | |
| 17.12.2024 | 1.1.0.1  | [rom_image] New ROM image | |
| 22.12.2024 | 1.1.0.2  | [core] PC bit 0 is now always 0 on JALR, [i2c] removed some redundancies | |
| 01.01.2025 | 1.1.0.3  | [i2c] Added clock stretching support | |
| 03.01.2025 | 1.1.0.4  | [i2c] Removed `leadout` state, it is not needed | |
| 20.01.2025 | 1.1.0.5  | [gpio] Added Port Set and Clear registers | |
| 27.01.2025 | 1.1.0.6  | [core] Added Zbb extension, [common] added functions for use with Zbb | |
| 29.01.2025 | 1.1.1.0  | New version | |
| 09.02.2025 | 1.1.1.1  | [core] make sure that NMI is only accepted if not already executing an NMI [mtime] register access after mtime counter update | |
| 20.03.2025 | 1.1.1.2  | Rewrite wdt code | |
| 21.03.2025 | 1.1.1.3  | Added CRC module | |
| 21.03.2025 | 1.1.2.0  | New version 1.1.2 | |
| 22.04.2025 | 1.1.2.1  | [crc] changed counting sequence of the CRC module | |
| 01.05.2025 | 1.1.2.2  | [core] moved register selection signals to if_id record | |
| 02.05.2025 | 1.1.2.3  | [core] when in debug, memory access is acknowledged even when misaligned or access error | |
| 03.05.2025 | 1.1.2.4  | [ricsv] used generic stubs for non-used I/O address space, memory accesses are now acknowledged | |
| 29.05.2025 | 1.1.2.5  | [core] remove RAM block for debug when OCD is turned of and registers are in RAM block | |
| 08.06.2025 | 1.1.2.6  | [riscv/address_decode] now have new generic HAVE_BOOTLOADER_ROM, [dm] new cmderr when memory access times out | |
| 10.06.2025 | 1.1.2.7  | [all I/O] correct response on misaligned access |
| 11.06.2025 | 1.1.2.8  | [core] always decode instruction, id_ex.ismem always reset | |

