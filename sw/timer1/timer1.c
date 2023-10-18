
// #################################################################################################
// # This file is part of the THUAS RV32 processor                                                 #
// # ********************************************************************************************* #
// # BSD 3-Clause License                                                                          #
// #                                                                                               #
// # Copyright (c) 2023, Jesse op den Brouw. All rights reserved.                                  #
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
// # Example of TIMER1 to use interrupt (with handler)                                             #
// #################################################################################################

#include <thuasrv32.h>

/* Frequency of the DE0-CV board */
#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
/* Transmission speed */
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* Interrupt frequency TIMER1 */
#define TIMER1_FREQ (1UL)

int main(void)
{
	/* Get clock frequency */
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;

	/* Redirect all traps to handler */
	set_mtvec(trap_handler, TRAP_DIRECT_MODE);

	/* Set CMPT register */
	timer1_setcompare(speed/TIMER1_FREQ-1UL);
	/* Enable interrupt */
	timer1_enable_interrupt();
	/* Enable timer */
	timer1_enable();

	/* Enable global IRQ */
	enable_irq();

	//timer1_disable();

	while(1);
}

/* Trap handler, just invert POUT2
 * and clear interrupt flag */
__attribute__((interrupt))
void trap_handler(void)
{
	GPIOA->POUT ^= (1 << 15) | (1 << 2);
	timer1_clear_interrupt();
}
