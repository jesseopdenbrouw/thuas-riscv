
volatile int x = 4;

int mult(void) {
        volatile int a = 1000, b = 3, m;
        m = a*b;
	return m;
}

int main(void) {
        mult();
}

