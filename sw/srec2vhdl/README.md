# srec2vhdl

This is a self made program that converts a Motorola S-record file
to a VHDL file suitable for inclusion in a VHDL description.

srec2vhdl v0.3 -- an S-record to VHDL table converter
Usage: srec2vhdl [-vqfbhw0d -i <arg>] inputfile [outputfile]
   -f        Full table output
   -i <arg>  Indent by <arg> spaces
   -v        Verbose
   -q        Quiet. Only errors are reported
   -b        Byte output (default)
   -h        Halfword output (16 bits, Little Endian)
   -w        Word output (32 bits, Little Endian)
   -0        Output unused data as 0's
   -d        Output unused data as don't care
If outputfile is omitted, stdout is used
Program size must be less then 1 MB

## NOTE

The address of the first record is used as an offset
so that the first records starts at vector element 0.

## Status

Works.
