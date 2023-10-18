# i2c1findslaves

Find all slaves on I2C1 peripheral.

# Description

This program searches for slaves on the I2C1 bus.
If a slave is found, the address is printed in hex.

The program issues a series of addresses to the bus,
including a START and a STOP. After the address is
written the Acknowledge Fail flag (AF) is tested.
If AF = 1 then there is no slave at that address.
If AF = 0 then there is a slave at that address.
Tested with a Seeed Arduino Sensor Kit.

Power up the Seeed Arduino Sensor Kit with jumper
cables from the DE0-CV board. Use 3.3 V!!! Next,
connect SDA and SCL

## Output
With the Seeed Arduino Sensor Kit, slaves are found
at addresses 0x19, 0x38, 0x3c and 0x77.

## Status

Tested with a Seeed Arduino Sensor Kit.
Works on the board.
