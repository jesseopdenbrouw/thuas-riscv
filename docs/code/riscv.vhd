library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.processor_common.all;

-- The microcontroller
entity riscv is
    generic (
          -- The frequency of the system
          SYSTEM_FREQUENCY : integer := 50000000;
          -- Frequecy of the hardware clock
          CLOCK_FREQUENCY : integer := 1000000;
          -- RISCV E (embedded) of RISCV I (full)
          HAVE_RISCV_E : boolean := false;
          -- Do we have the integer multiply/divide unit?
          HAVE_MULDIV : boolean := TRUE;
          -- Fast divide (needs more area)?
          FAST_DIVIDE : boolean := TRUE;
          -- Do we have Zba (sh?add)
          HAVE_ZBA : boolean := false;
          -- Do we have Zbs (bit instructions)?
          HAVE_ZBS : boolean := false;
          -- Do we have Zicond (czero.{eqz|nez})?
          HAVE_ZICOND : boolean := false;
          -- Do we enable vectored mode for mtvec?
          VECTORED_MTVEC : boolean := TRUE;
          -- Do we have registers is RAM?
          HAVE_REGISTERS_IN_RAM : boolean := TRUE;
          -- Do we have a bootloader ROM?
          HAVE_BOOTLOADER_ROM : boolean := TRUE;
          -- Address width in bits, size is 2**bits
          ROM_ADDRESS_BITS : integer := 16;
          -- Address width in bits, size is 2**bits
          RAM_ADDRESS_BITS : integer := 15;
          -- 4 high bits of ROM address
          ROM_HIGH_NIBBLE : memory_high_nibble := x"0";
          -- 4 high bits of boot ROM address
          BOOT_HIGH_NIBBLE : memory_high_nibble := x"1";
          -- 4 high bits of RAM address
          RAM_HIGH_NIBBLE : memory_high_nibble := x"2";
          -- 4 high bits of I/O address
          IO_HIGH_NIBBLE : memory_high_nibble := x"F";
          -- Do we use fast store?
          HAVE_FAST_STORE : boolean := false;
          -- Do we have UART1?
          HAVE_UART1 : boolean := TRUE;
          -- Do we have SPI1?
          HAVE_SPI1 : boolean := TRUE;
          -- Do we have SPI2?
          HAVE_SPI2 : boolean := TRUE;
          -- Do we have I2C1?
          HAVE_I2C1 : boolean := TRUE;
          -- Do we have I2C2?
          HAVE_I2C2 : boolean := TRUE;
          -- Do we have TIMER1?
          HAVE_TIMER1 : boolean := TRUE;
          -- Do we have TIMER2?
          HAVE_TIMER2 : boolean := TRUE;
          -- UART1 BREAK triggers system reset
          UART1_BREAK_RESETS : boolean := false
         );
    port (I_clk : in std_logic;
          I_areset : in std_logic;
          -- GPIOA
          I_gpioapin : in data_type;
          O_gpioapout : out data_type;
          -- UART1
          I_uart1rxd : in std_logic;
          O_uart1txd : out std_logic;
          -- I2C1
          IO_i2c1scl : inout std_logic;
          IO_i2c1sda : inout std_logic;
          -- I2C2
          IO_i2c2scl : inout std_logic;
          IO_i2c2sda : inout std_logic;
          -- SPI1
          O_spi1sck : out std_logic;
          O_spi1mosi : out std_logic;
          I_spi1miso : in std_logic;
          O_spi1nss : out std_logic;
          -- SPI2
          O_spi2sck : out std_logic;
          O_spi2mosi : out std_logic;
          I_spi2miso : in std_logic;
          -- TIMER2
          O_timer2oct : out std_logic;
          IO_timer2icoca : inout std_logic;
          IO_timer2icocb : inout std_logic;
          IO_timer2icocc : inout std_logic
         );
end entity riscv;
