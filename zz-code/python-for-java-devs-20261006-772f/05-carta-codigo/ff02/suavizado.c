/* Exponential smoothing: out[i] = alpha * x[i] + (1 - alpha) * out[i - 1]. */
void ema(const double *x, double *out, long n, double alpha) {
    double s = x[0];
    for (long i = 0; i < n; i++) {
        s = alpha * x[i] + (1.0 - alpha) * s;
        out[i] = s;
    }
}

double add(double a, double b) { return a + b; }
