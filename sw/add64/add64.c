int main(void) {

	volatile long long int r, a = 0x7fffffffffffffff, b = 7;

	r = a + b;

	return 0;
}
