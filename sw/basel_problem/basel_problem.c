/*
 * basel_problem -- \sum_{i=1}^\infty \dfrac{1}{i^2}
 *
 * Set the steps in variable n
 *
 * For 1000 steps, run the simulation for 8500 us.
 */

int main(void) {

    int k, n = 1000;


    /* View in RAM */
    volatile float basel = 0.0f;

    for (k = 1; k <= n; k++) {
        basel = basel + 1.0f/(k*k);
    }

    return 0;
}
