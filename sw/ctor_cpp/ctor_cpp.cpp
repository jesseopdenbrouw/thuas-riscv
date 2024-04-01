/*
 * ctor_cpp.cpp -- test if constructors are called before main
 *
 * note: implementing destructors create a binary that is to big
 * to fit in the ROM.
 *
 */


#include <thuasrv32.h>

class myClass {
	public:
	myClass() {
		i = 5;
		k = 3;
		j = 3.14;
		uart1_init(BAUD_RATE, UART_CTRL_EN);
		uart1_puts((char *) "Constructor myClass called\r\n");
	}
	int getI(void) {
		return i;
	}

	private:
		int i;
		int k;
		double j;
};

myClass x, y;

int main(void)
{
	uart1_puts((char *) "Did you see the constructors called?\r\n");
}
