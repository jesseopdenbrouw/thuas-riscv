/*
 * float.c -- Some simple test to see if the float libs are
 *            working correctly. Calculations are done with
 *            software functions.
 *
 *
 *
 *
 */

int main(void)
{
	/* Creates a variable on the stack */
	volatile float f = 1.0f;

	f = f + 2.0f;

	f = f / -3.0f;

	f = f * -25.0f;

	return 0;
}
