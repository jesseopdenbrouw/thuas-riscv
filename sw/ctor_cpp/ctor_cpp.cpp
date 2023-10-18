


#include <thuasrv32.h>

class myClass {
	public:
	myClass() {
		i = 5;
		k = 3;
		j = 3.14;
		uart1_init(BAUD_RATE, UART_CTRL_NONE);
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

}
