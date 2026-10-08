#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>

namespace py = pybind11;

// Suavizado exponencial sobre un arreglo de NumPy.
py::array_t<double> ema(py::array_t<double, py::array::c_style | py::array::forcecast> x, double alpha) {
    auto in = x.unchecked<1>();
    py::ssize_t n = in.shape(0);
    py::array_t<double> out(n);
    auto o = out.mutable_unchecked<1>();
    double s = in(0);
    for (py::ssize_t i = 0; i < n; i++) {
        s = alpha * in(i) + (1 - alpha) * s;
        o(i) = s;
    }
    return out;
}

PYBIND11_MODULE(ema_pb, m) { m.def("ema", &ema); }
