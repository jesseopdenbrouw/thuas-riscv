# FreeRTOS Demo for the THUASRV32 Processor (preliminary)

(Based on the NEORV32 version by S. Nolting.)

This example shows how to run [FreeRTOS](https://www.freertos.org/) on the THUASRV32 processor. It features the default
"blinky_demo" and the more sophisticated "full_demo" demo applications. See the comments in `main.c` and the according
source files for more information.

The chip-specific extensions folder (`chip_specific_extensions/thuasrv32`) should be in `$(FREERTOS_HOME)/Source/portable/GCC/RISC-V/chip_specific_extensions`, but is placed in this source directory for simplicity.

**:information_source: Tested with FreeRTOS version V10.4.4+**


## Requirements

* Hardware
  * peripherals: MTIME (machine timer), UART1, GPIOA

* Software
  * THUASRV32 software framework
  * RISC-V gcc
  * FreeRTOS
  * application-specific configuration of `FreeRTOSConfig.h` (especially `configCPU_CLOCK_HZ`). This value must always be 1000000 as MTIME has a base count frequency of 1 MHz (derived from the system clock frequency).


## Instructions

Download FreeRTOS from the [official GitHub repository](https://github.com/FreeRTOS/FreeRTOS) or from the its official homepage.

    $ git clone https://github.com/FreeRTOS/FreeRTOS.git

Open the makefile from this example folder and configure the `FREERTOS_HOME` variable to point to your FreeRTOS home folder.

    FREERTOS_HOME ?= <path-to-FreeRTOS-software>

Open de makefile and select the application to run. Set `WHICH_DEMO` to `mainCREATE_SIMPLE_BLINKY_DEMO_ONLY=0` to run the comprehensive demo or set to `WHICH_DEMO ?= mainCREATE_SIMPLE_BLINKY_DEMO_ONLY=1` to run the simple blinky demo.

Compile the THUASRV32 executable.

    $ make clean all

Upload the executable (`main.srec`) to the processor via the bootloader and execute it.

Please do not use link time optimization!

## Notes

The configuration of the FreeRTOS home folder (via `FREERTOS_HOME`) is corrupted if the compiler shows the following error:

```
main.c:36:10: fatal error: FreeRTOS.h: No such file or directory
   36 | #include <FreeRTOS.h>
      |          ^~~~~~~~~~~~
compilation terminated.
make: *** [makefile:203: main.c.o] Error 1
```

