# THUAS RISC-V RV32 library

This is the parent directory of the THUAS RV32 library files.

## Libraries

* `csr` - functions for manipulating CSRs, including setting up trap handlers and reading TIME, CYCLE and INSTRET as 64-bit numbers.
* `i2c` - functions for handling I2C setup and transmissions.
* `spi` - functions for handling SPI setup and transmissions.
* `syscalls` - functions for imitating system calls, when not using traps. See below.
* `timer` - functions for using the timers.
* `uart` - functions for using the UART, including formatted printing.
* `gpio` - functions for using GPIOA.
* `util` - some utility functions

The result of compilation will be the library `libthuasrv32.a`.

## specs files
There are two specs files: `thuas.specs` and `nano.specs`. The `thuas.specs` file sets up linking of the THUAS library file `libthuasrv32.a`. The `nano.specs` file sets up linking of the nano library but overrides linking of default system calls. The system calls use non-trapped call emulation. You need to set up the linker with `--specs=<path-to>/thuas.specs --specs=<path-to>/nano.specs`. To use the trapped system calls, set up the default nano.specs: `--specs=nano.specs`.
