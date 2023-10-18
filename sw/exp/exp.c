/*
 * exp.c -- Program to calculate Euler's number e.
 *          Uses floats, multiplication and division.
 */

volatile float e = 0.0f;
volatile float fac = 1.0f;

int main(void)
{
	int i;

	for (i = 1; i<20; i++)
	{
		e = e + 1.0f/fac;
		fac = fac * i;
	}

	return 0;
}
