
# upload

This program uploads an S-record file to the THUAS RISC-V processor.
For use with the onboard bootloader. After reset, the bootloader
waits for about 5 seconds @ 50 MHz for `upload` to contact. Start
the `upload` program within these 5 seconds and the S-record file
will be transferred. Currently, the transmission speed is one of
9600 bps or 115200 bps.

It currently build on Linux, GCC MinGW for Windows and Visual Studio 2022.

Usage:

    upload -vnrB -d <device> -b <baud> -t <timeout> -s <sleep> srec-file

-v: verbose

-r: run application after upload

-n: don't use handshake

-B: send BREAK condition prior to uploading

device: set device, default is /dev/ttyUSB0 for Linux, COM1 for Windows

timeout: set timeout for device input, in deci seconds (0.1 sec), default is 10

sleep: sleep after character transmission, in milliseconds, default is 0

baud rate: one of 9600, 115200 and 230400

