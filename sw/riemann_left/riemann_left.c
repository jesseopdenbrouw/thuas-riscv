/*
 * riemannn_left -- integration using Riemann Left Sum
 *
 * Set the steps in variable n
 *
 * For 10 steps, run the simulation for 3200 us.
 * Link with -lm
 */


/* View in RAM */
volatile float result = -1.0f;
volatile float sum = 0.0f;
volatile float deltax;

#include <math.h>

float f(float x) {
    float y;
    y = sinf(x);
    return y*y;
}

int main() {

    int k, n = 10;

    float a = 0.0f;
    float b = 6.28318530717958647692f;

    deltax = (b - a) / n;


    for (k = 0; k < n; k++) {
        sum = sum + f(a + k*deltax) * deltax;
    }

    result = sum;

    return 0;
}
