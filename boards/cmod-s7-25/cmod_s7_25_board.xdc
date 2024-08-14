## Clock signal
set_property -dict {PACKAGE_PIN M9 IOSTANDARD LVCMOS33} [get_ports {I_clk} ]
# Clock has 12 MHz oscillator (83.333333 ns)
#create_clock -period 83.333 -name I_clk -waveform {0.000 41.667} -add [get_ports {I_clk} ]
# When using a MMCM at 100 MHz
#create_clock -period 10.000 -name I_clk -waveform {0.000 5.000} -add [get_ports {I_clk} ]
# When using a MMCM at 125 MHz
create_clock -period 8.000 -name I_clk -waveform {0.000 4.0000} -add [get_ports {I_clk} ]
#create_generated_clock -multiply_by 9 -source [get_ports I_clk] -name override_clock [get_pins {clk_mult0/inst/mmcm_adv_inst/CLKOUT0}]

## Reset (BTN0)
set_property -dict {PACKAGE_PIN D2 IOSTANDARD LVCMOS33} [get_ports {I_areset}]

## Push buttons (BTN1)
set_property -dict {PACKAGE_PIN D1 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[0]} ]

## LEDS (LED1, LED2, LED3, LED4)
set_property -dict {PACKAGE_PIN E2 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[0]} ]
set_property -dict {PACKAGE_PIN K1 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[1]} ]
set_property -dict {PACKAGE_PIN J1 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[2]} ]
set_property -dict {PACKAGE_PIN E1 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[3]} ]

## RGB1 (LED0_R, LED0_G, LED0_B)
set_property -dict {PACKAGE_PIN F2 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[4]} ]
set_property -dict {PACKAGE_PIN D3 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[5]} ]
set_property -dict {PACKAGE_PIN F1 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[6]} ]

## UART1 (UART_TXD_IN, UART_RXD_OUT)
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {I_uart1rxd}]
set_property -dict {PACKAGE_PIN L12 IOSTANDARD LVCMOS33} [get_ports {O_uart1txd}]

## I2C1 - pins (PIO01, PIO02)
set_property -dict {PACKAGE_PIN L1 IOSTANDARD LVCMOS33} [get_ports {IO_i2c1scl}]
set_property -dict {PACKAGE_PIN M4 IOSTANDARD LVCMOS33} [get_ports {IO_i2c1sda}]

## I2C2 - pins (PIO30, PIO31)
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {IO_i2c2scl}]
set_property -dict {PACKAGE_PIN J11 IOSTANDARD LVCMOS33} [get_ports {IO_i2c2sda}]

## SPI1 (PIO26, PIO27, PIO28, PIO29)
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVCMOS33} [get_ports {O_spi1sck}]
set_property -dict {PACKAGE_PIN K14 IOSTANDARD LVCMOS33} [get_ports {O_spi1mosi}]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {I_spi1miso}]
set_property -dict {PACKAGE_PIN L13 IOSTANDARD LVCMOS33} [get_ports {O_spi1nss}]

## SPI2 (PIO3, PIO4, PIO5, PIO6)
set_property -dict {PACKAGE_PIN M3 IOSTANDARD LVCMOS33} [get_ports {O_spi2sck}]
set_property -dict {PACKAGE_PIN N2 IOSTANDARD LVCMOS33} [get_ports {O_spi2mosi}]
set_property -dict {PACKAGE_PIN M2 IOSTANDARD LVCMOS33} [get_ports {I_spi2miso}]
# Software generated Slave Select
set_property -dict {PACKAGE_PIN P3 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[14]} ]

## TIMER2 OC/PWM (PIO7, PIO8, PIO9, PIO16)
set_property -dict {PACKAGE_PIN N3 IOSTANDARD LVCMOS33} [get_ports {O_timer2oct}]
set_property -dict {PACKAGE_PIN P1 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icoca}]
set_property -dict {PACKAGE_PIN N1 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icocb}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {IO_timer2icocc}]


## Fillers for GPIOA POUT (PIO17, PIO18, PIO19, PIO20, PIO21, PIO22, PIO23)
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[7]} ]
set_property -dict {PACKAGE_PIN N13 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[8]} ]
set_property -dict {PACKAGE_PIN N15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[9]} ]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[10]} ]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[11]} ]
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[12]} ]
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVCMOS33} [get_ports {O_gpioapout[13]} ]

## Fillers for GPIOA PIN (PIO40 to PIO43)
set_property -dict {PACKAGE_PIN C5 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[1]} ]
set_property -dict {PACKAGE_PIN A2 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[2]} ]
set_property -dict {PACKAGE_PIN B2 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[3]} ]
set_property -dict {PACKAGE_PIN B1 IOSTANDARD LVCMOS33} [get_ports {I_gpioapin[4]} ]

## JTAG connections (PIO44 to PIO48)
set_property -dict {PACKAGE_PIN C1 IOSTANDARD LVCMOS33} [get_ports {I_trst} ]
set_property -dict {PACKAGE_PIN B3 IOSTANDARD LVCMOS33} [get_ports {I_tms} ]
set_property -dict {PACKAGE_PIN B4 IOSTANDARD LVCMOS33} [get_ports {O_tdo} ]
set_property -dict {PACKAGE_PIN A3 IOSTANDARD LVCMOS33} [get_ports {I_tdi} ]
set_property -dict {PACKAGE_PIN A4 IOSTANDARD LVCMOS33} [get_ports {I_tck} ]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]
#set_property INTERNAL_VREF 0.675 [get_iobanks 34]

set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE 33 [current_design]
set_property CONFIG_MODE SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]

