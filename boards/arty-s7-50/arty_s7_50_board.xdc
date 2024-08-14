## Clock signal
set_property -dict {PACKAGE_PIN R2 IOSTANDARD LVCMOS33} [get_ports {I_clk} ]
create_clock -period 8.000 -name I_clk -waveform {0.000 4.000} -add [get_ports {I_clk} ]
#create_clock -period 9.000 -name I_clk -waveform {0.000 4.500} -add [get_ports {I_clk} ]
#create_clock -period 10.000 -name I_clk -waveform {0.000 5.000} -add [get_ports {I_clk} ]

## Reset
set_property -dict {PACKAGE_PIN C18 IOSTANDARD LVCMOS33} [get_ports {I_areset}]

## Switches
set_property -dict {PACKAGE_PIN H14 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[0]} ]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[1]} ]
set_property -dict {PACKAGE_PIN G18 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[2]} ]
set_property -dict {PACKAGE_PIN M5  IOSTANDARD SSTL135}  [get_ports {I_gpioapin[3]} ]

## Push buttons
set_property -dict {PACKAGE_PIN G15 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[4]} ]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[5]} ]
set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[6]} ]
set_property -dict {PACKAGE_PIN H13 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[7]} ]

## LEDS
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[0]} ]
set_property -dict {PACKAGE_PIN F13 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[1]} ]
set_property -dict {PACKAGE_PIN E13 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[2]} ]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[3]} ]

## RGB1
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[4]} ]
set_property -dict {PACKAGE_PIN G17 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[5]} ]
set_property -dict {PACKAGE_PIN F15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[6]} ]

## RGB2
set_property -dict {PACKAGE_PIN E15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[7]} ]
set_property -dict {PACKAGE_PIN F18 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[8]} ]
set_property -dict {PACKAGE_PIN E14 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[9]} ]

## UART1
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {I_uart1rxd}]
set_property -dict {PACKAGE_PIN R12 IOSTANDARD LVCMOS33} [get_ports {O_uart1txd}]

## I2C1 - Connected to ChipKit/Arduino
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {IO_i2c1scl}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {IO_i2c1sda}]

## I2C2 - Connected to ChipKit/Arduino (IO40 = SDA, IO41 = SCL)
set_property -dict {PACKAGE_PIN U15 IOSTANDARD LVCMOS33} [get_ports {IO_i2c2scl}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {IO_i2c2sda}]

## SPI1
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {O_spi1sck}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {O_spi1mosi}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {I_spi1miso}]
set_property -dict {PACKAGE_PIN P13 IOSTANDARD LVCMOS33} [get_ports {O_spi1nss}]

## SPI2 -- connected to ChipKit/Arduino SPI
set_property -dict {PACKAGE_PIN G16 IOSTANDARD LVCMOS33} [get_ports {O_spi2sck}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {O_spi2mosi}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports {I_spi2miso}]
# Software generated Slave Select
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[14]} ]

## TIMER2 OC/PWM /CK_IO26,27,28,29
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports {O_timer2oct}]
set_property -dict {PACKAGE_PIN R11 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icoca}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icocb}]
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icocc}]

## Fill /CK_IO30,31,32,33
set_property -dict {PACKAGE_PIN T12 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[10]} ]
set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[11]} ]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[12]} ]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[13]} ]

## PMODB, used for JTAG, pins 1 to 4, 7 
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports {I_tck} ]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports {I_tdi} ]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {I_tms} ]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports {I_trst} ]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {O_tdo} ]


set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
set_property INTERNAL_VREF 0.675 [get_iobanks 34]

set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]

# Doesn't work here
#set_property SEVERITY {Warning} [get_drc_checks NSTD-1]
#set_property SEVERITY {Warning} [get_drc_checks UCIO-1]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]

