/*
 * riscv-largerom.ld - linker script for the THUAS RISC-V
 *                     bare metal processor with enlarged ROM
 */

/* Entry symbol */
ENTRY( _start )

/* Memory */
MEMORY
{
   ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 128K
   RAM (rw)  : ORIGIN = 0x20000000, LENGTH = 32K
   IO (rw)   : ORIGIN = 0xf0000000, LENGTH = 16K
}

/* Stack pointer global symbol. Stack size for
 * heap calculation */
__stack_pointer$ = ORIGIN(RAM) + LENGTH(RAM);
__stack_size = 0x400;

PHDRS
{
  ROM PT_LOAD;
}

SECTIONS
{
  /* Program code */
  .text : { 

    /* Startup code is first in line */
    _stext = .;
    *(.text.start_up_code)
    *(.text.start_up_code_c)
    *(.text)
    *(.text*) 
    *(.text.unlikely)
    *(.text.unlikely.*)
    *(.eh_frame)

    KEEP (*(.init))
    KEEP (*(.fini))

    . = ALIGN(4);
    _etext = .;

   } >ROM :ROM


  /* Read-only data in ROM */
  .rodata :
  {
    _srodata = .;
    *(.rdata)
    *(.rdata.*)
    *(.rodata)
    *(.rodata.*)
    *(.srodata)
    *(.srodata.*)
    *(.gnu.linkonce.r.*)
    . = ALIGN(4);
    _erodata = .;
  } >ROM :ROM


  .preinit_array     :
  {
    /*. = ALIGN(4); */
    PROVIDE_HIDDEN (__preinit_array_start = .);
    KEEP (*(.preinit_array*))
    PROVIDE_HIDDEN (__preinit_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  .init_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__init_array_start = .);
    KEEP (*(SORT(.init_array.*)))
    KEEP (*(.init_array*))
    PROVIDE_HIDDEN (__init_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  .fini_array :
  {
    . = ALIGN(4);
    PROVIDE_HIDDEN (__fini_array_start = .);
    KEEP (*(SORT(.fini_array.*)))
    KEEP (*(.fini_array*))
    PROVIDE_HIDDEN (__fini_array_end = .);
    . = ALIGN(4);
  } >ROM :ROM

  . = ALIGN(4);
  _start_of_rom_to_copy = .;
  PROVIDE(_start_of_rom_to_copy = .);

  _sidata = LOADADDR(.sdata);

  /* Initialization data in RAM */
  .sdata : {
    __global_pointer$ = . + 0x800;
    _sdata = .;
    *(.data)
    *(.data*)
    *(sdata)
    *(sdata.*)
    . = ALIGN(4);
  } >RAM AT>ROM
    . = ALIGN(4);
    _edata = .;

  . = ALIGN(4);
  .bss :
  {
    /* This is used by the startup in order to initialize the .bss section */
    _sbss = .;         /* define a global symbol at bss start */
    *(.sbss)
    *(.sbss*)
    *(.bss)
    *(.bss*)
    *(COMMON)

    . = ALIGN(4);
    _ebss = .;         /* define a global symbol at bss end */
  } >RAM AT>RAM


  /* End of uninitialized data segment (used by syssbrk.c for heap) */
  PROVIDE( end = . );
  _end = ALIGN(8);

  /* Maybe useful */
  _start_ram = ORIGIN(RAM);
  _start_io = ORIGIN(IO);
}

