import subprocess, time, statistics, sys

def bench(cmd, reps=30):
    for _ in range(3):
        subprocess.run(cmd, capture_output=True)
    xs = []
    for _ in range(reps):
        t0 = time.perf_counter()
        subprocess.run(cmd, capture_output=True)
        xs.append((time.perf_counter() - t0) * 1000)
    xs.sort()
    return statistics.median(xs), xs[int(len(xs)*0.95)-1], min(xs)

casos = {
    "python -c pass": ["/opt/homebrew/bin/python3.14", "-c", "pass"],
    "python -S -c pass": ["/opt/homebrew/bin/python3.14", "-S", "-c", "pass"],
    "python -c import json,csv,pathlib": ["/opt/homebrew/bin/python3.14", "-c", "import json,csv,pathlib,argparse"],
    "java Hello": ["java", "-cp", ".", "Hello"],
    "java -XX:TieredStopAtLevel=1 -Xshare:auto Hello": ["java", "-XX:TieredStopAtLevel=1", "-Xshare:auto", "-cp", ".", "Hello"],
}
for n, c in casos.items():
    med, p95, mn = bench(c)
    print(f"{n:50s} mediana {med:7.1f} ms   p95 {p95:7.1f} ms   min {mn:7.1f} ms")
