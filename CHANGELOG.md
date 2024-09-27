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
|:----------:|:--------:|:-------:|:-----:|
| 13.08.2024 | 1.0.0.0  | Based on version 0.9.10.1 + on-chip debugging | |
| 29.08.2024 | 1.0.0.1  | tdo = tdi when OCD is disabled, minor change in multipliers | |
| 04.09.2024 | 1.0.0.2  | Some minor changes, no real hardware changes | |
| 07.09.2024 | 1.0.1.0  | [dm] Added auto-increment on memory accesses | |
| 09.09.2024 | 1.0.1.1  | [dm] Fix bug in auto-increment calculation | |
| 17.09.2024 | 1.0.1.2  | Removed unused signal | |
| 21.09.2024 | 1.0.1.3  | Minor comment edits, moved a signal in core | |
| 27.09.2024 | 1.0.1.4  | MEPC has bit 0 set to hard 0, PC witj JARL has bit 0 set to hard 0 | |

