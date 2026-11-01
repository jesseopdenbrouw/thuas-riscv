-- srec2vhdl table generator
-- for input file 'assembler.srec'
-- date: Sun Nov  1 08:07:11 2026


library ieee;
use ieee.std_logic_1164.all;

library work;
use work.processor_common.all;

package rom_image is
    constant rom_contents : memory_type := (
           0 => x"97110020",
           1 => x"93810180",
           2 => x"17810020",
           3 => x"130181ff",
           4 => x"97020000",
           5 => x"93824206",
           6 => x"73905230",
           7 => x"93028000",
           8 => x"73900230",
           9 => x"13050000",
          10 => x"13051500",
          11 => x"13051500",
          12 => x"13051500",
          13 => x"13051500",
          14 => x"13051500",
          15 => x"13051500",
          16 => x"13051500",
          17 => x"13051500",
          18 => x"13051500",
          19 => x"13051500",
          20 => x"13051500",
          21 => x"13051500",
          22 => x"13051500",
          23 => x"13051500",
          24 => x"6ff09ffc",
          25 => x"6f000000",
          26 => x"ffffffff",
          27 => x"eeeeeeee",
          28 => x"dddddddd",
          29 => x"f3222034",
          30 => x"63c80200",
          31 => x"f3221034",
          32 => x"93824200",
          33 => x"73901234",
          34 => x"b70200f0",
          35 => x"93824210",
          36 => x"23a00200",
          37 => x"13000000",
          38 => x"73002030",
          39 => x"78563412",
          40 => x"21436587"
            );
end package rom_image;
