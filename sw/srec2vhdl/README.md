# srec2vhdl

This is a self made program that converts a Motorola S-record file
to a VHDL file suitable for inclusion in a VHDL description.

```
srec2vhdl v0.4 -- an S-record to VHDL table converter
Usage: srec2vhdl [-fvqbhwd0xB] [-i <arg>] inputfile [outputfile]
   -f        Full table output
   -i <arg>  Indent by <arg> spaces
   -v        Verbose
   -q        Quiet. Only errors are reported
   -b        Byte output (default)
   -h        Halfword output (16 bits, Little Endian)
   -w        Word output (32 bits, Little Endian)
   -d        Double word output (64 bits, Little Endian)
   -0        Output unused data as 0's
   -x        Output unused data as don't care
   -B        Output as bootloader ROM
If outputfile is omitted, stdout is used
Program size must be less then 10 MB
```

The address of the first record is used as an offset
so that the first record starts at vector element 0.

## Status

Works.
