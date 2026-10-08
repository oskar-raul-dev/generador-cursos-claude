#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>

namespace nb = nanobind;
using Out = nb::ndarray<nb::numpy, double, nb::ndim<1>>;

// Exponential smoothing over a NumPy array.
Out ema(nb::ndarray<const double, nb::ndim<1>, nb::c_contig> x, double alpha) {
    size_t n = x.shape(0);
    const double *in = x.data();
    double *out = new double[n];
    nb::capsule owner(out, [](void *p) noexcept { delete[] static_cast<double *>(p); });
    double s = in[0];
    for (size_t i = 0; i < n; i++) {
        s = alpha * in[i] + (1 - alpha) * s;
        out[i] = s;
    }
    return Out(out, {n}, owner);
}

NB_MODULE(ema_nb, m) { m.def("ema", &ema); }
