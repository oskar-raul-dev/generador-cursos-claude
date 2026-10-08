import subprocess, time
for name, cmd in [("CPython", ["python", "-c", "pass"]), ("GraalPy", ["graalpy/bin/graalpy", "-c", "pass"]),
                  ("Jython", ["java", "-jar", "jython.jar", "-c", "pass"])]:
    best = min((lambda s: (subprocess.run(cmd, check=True), time.perf_counter() - s)[1])(time.perf_counter()) for _ in range(3))
    print(f"arranque {name}: {best:.2f} s")
