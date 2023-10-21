// #################################################################################################
// # This file is part of the THUAS RV32 processor                                                 #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2022, Jesse op den Brouw. All rights reserved.                                  #
// #                                                                                               #
// # Redistribution and use in source and binary forms, with or without modification, are          #
// # permitted provided that the following conditions are met:                                     #
// #                                                                                               #
// # 1. Redistributions of source code must retain the above copyright notice, this list of        #
// #    conditions and the following disclaimer.                                                   #
// #                                                                                               #
// # 2. Redistributions in binary form must reproduce the above copyright notice, this list of     #
// #    conditions and the following disclaimer in the documentation and/or other materials        #
// #    provided with the distribution.                                                            #
// #                                                                                               #
// # 3. Neither the name of the copyright holder nor the names of its contributors may be used to  #
// #    endorse or promote products derived from this software without specific prior written      #
// #    permission.                                                                                #
// #                                                                                               #
// # THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS   #
// # OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF               #
// # MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE    #
// # COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,     #
// # EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE #
// # GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED    #
// # AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING     #
// # NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED  #
// # OF THE POSSIBILITY OF SUCH DAMAGE.                                                            #
// # ********************************************************************************************* #
// # Direct interrupt handling.                                                                    #
// #################################################################################################

#include <stdint.h>
#include <malloc.h>
#include <sys/time.h>
#include <string.h>
#include <unistd.h>
#include <stdio.h>

#include <thuasrv32.h>

/* Set to 1 to use printf(), uses system calls.
 * Set to 0 to use sprintf()/uart1_puts(), uses
 * at most sbrk system call */
#define USE_PRINTF (0)

/* Should be loaded by the Makefile */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

int main(int argc, char *argv[], char *envp[])
{
	struct timeval tv;
	uint32_t hour, min, sec;
	uint32_t ebreak_counter = 0;

#if USEPRINTF != 1
	char buffer[40] = {0};
#endif

	/* Set the trap handler vector */
	set_mtvec(trap_handler_direct, TRAP_DIRECT_MODE);

	/* Initialize the USART*/
	uart1_init(BAUD_RATE, UART_CTRL_RCIE);

	/* Activate TIMER1 with a cycle of 1 Hz */
	/* for a 50 MHz clock. Use interrupt. */
	TIMER1->CMPT = csr_read(0xfc1)/2-1;
	/* Bit 0 = enable, bit 4 is interrupt enable */
	TIMER1->CTRL = (1<<4)|(1<<0);

	/* Activate TIMER2 compare match T with a cycle of 0.5 Hz */
	/* for a 50 MHz clock. Use interrupt. */
	TIMER2->PRSC = csr_read(0xfc1)/10000-1;
	TIMER2->CMPT = 9999;
	TIMER2->CTRL = (1<<4)|(1<<0);

	/* Activate SPI1 transmission complete interrupt */
	/* with /256 prescaler, 8-bit data, mode 0 */
	SPI1->CTRL = (7 << 8) | (1 << 3);

	/* Activate I2C1 transmit/receive complete interrupt */
	/* Standard mode, 100 kHz */
	I2C1->CTRL = I2C_PRESCALER_SM(csr_read(0xfc1)) | (1 << 3);

	/* External input pin interrupt, pin 15, rising edge */	
	GPIOA->EXTC = (15 << 3) | (1 << 1);

	/* Enable RISC-V system timer IRQ */
	enable_external_timer_irq();

	/* Enable interrupts */
	enable_irq();

#if USEPRINTF == 1
	printf("\r\n");
	while(argc-- > 0) {
		printf("%s\r\n", *argv++);
	}
	printf("\r\n\nDisplaying the time passed since reset\r\n\n");
#else
	uart1_puts("\r\n");
	while(argc-- > 0) {
		uart1_puts(*argv++);
		uart1_puts("\r\n");
	}
	uart1_puts("\r\n\nDisplaying the time passed since reset\r\n\n");
#endif

	while (1) {
		/* Read in the time of the day */
		int status = gettimeofday(&tv, NULL);

		/* Produce hours, minutes and seconds */
		hour = tv.tv_sec / 3600UL;
		min = (tv.tv_sec / 60UL) % 60UL;
		sec = tv.tv_sec % 60UL;

		if (status == 0) {
#if USEPRINTF == 1
			printf("%05ld:%06ld", (int32_t) tv.tv_sec, tv.tv_usec);
			printf("   %02ld:%02ld:%02ld\r", hour, min, sec);
#else
			sprintf(buffer, "%05ld:%06ld   %02ld:%02ld:%02ld\r",
				(int32_t) tv.tv_sec, tv.tv_usec, hour, min, sec);
			uart1_puts(buffer);
#endif
		}

		/* Once in every +/- 10 seconds, produce an EBREAK call */
		ebreak_counter++;
		if (ebreak_counter == BAUD_RATE/24UL) {
			ebreak_counter = 0;
			__asm__ volatile ("ebreak;" :::);
			/* Start SPI1 transmission */
			SPI1->DATA = 0xff;
			/* Start I2C1 transmission, send START and STOP */
			/* Send address 0x48 (TMP102 device) */
			I2C1->CTRL |= (1 << 9) | (1 << 8);
			I2C1->DATA = (0x48 << 1);
		}
	}

	return 0;
}
