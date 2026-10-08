from invoke import task


@task
def comprimir(c):
    """Comprime el cierre del día."""
    c.run("gzip -kf cierre.csv")


@task(pre=[comprimir])
def respaldo(c):
    """Comprime y reporta el tamaño."""
    size = c.run("wc -c < cierre.csv.gz", hide=True).stdout.strip()
    print(f"respaldo listo: {size} bytes")
