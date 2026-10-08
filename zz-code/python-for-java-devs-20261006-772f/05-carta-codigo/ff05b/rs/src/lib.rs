use numpy::{PyArray1, PyReadonlyArray1};
use pyo3::prelude::*;

/// Exponential smoothing over a NumPy array.
#[pyfunction]
fn ema<'py>(py: Python<'py>, x: PyReadonlyArray1<'py, f64>, alpha: f64) -> PyResult<Bound<'py, PyArray1<f64>>> {
    let x = x.as_slice()?;
    let mut out = Vec::with_capacity(x.len());
    let mut s = x[0];
    for &v in x {
        s = alpha * v + (1.0 - alpha) * s;
        out.push(s);
    }
    Ok(PyArray1::from_vec(py, out))
}

#[pymodule]
fn ema_rs(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add_function(wrap_pyfunction!(ema, m)?)
}
