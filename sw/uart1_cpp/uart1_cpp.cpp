#include <cstdio>

#include <thuasrv32.h>

#ifndef F_CPU
#define F_CPU (50000000UL)
#endif
#ifndef BAUD_RATE
#define BAUD_RATE (9600UL)
#endif

/* The Uart class */
class Uart
{
	protected:
		Uart();
	public:
		Uart(Uart const &) = delete;
		Uart &operator=(Uart const &) = delete;
		static Uart& getUart1();
		virtual void putchar(char c) const = 0;
		void print(const char* s) const;
};

/* UART1 class */
class Uart1: public Uart
{
	private:
		Uart1();
    	friend class Uart;
	public:
		virtual void putchar(char c) const override;
};

/* Generic init code */
Uart::Uart()
{
}

/* Get UART1 instance */
Uart& Uart::getUart1()
{
	static Uart1 uart1;
	return uart1;
}

Uart1::Uart1()
{
	uint32_t speed = csr_read(0xfc1);
	speed = (speed == 0) ? F_CPU : speed;
	UART1->BAUD = speed/BAUD_RATE - 1;
}

/* Prints a character to the UART1 */
void Uart1::putchar(char c) const
{
        /* Transmit data */
        UART1->DATA = (uint8_t) c;
                
        /* Wait for transmission end */
        while ((UART1->STAT & 0x10) == 0);
}

/* Prints a string */
void Uart::print(const char *s) const
{
	if (s == NULL) {
		return;
	}

	while (*s != '\0') {
		putchar(*s++);
	}
}


int main(void)
{
	Uart& uart1 = Uart::getUart1();

	uart1.print("Hello using C++\r\n");
}

