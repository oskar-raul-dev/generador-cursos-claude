import sys, random, statistics, time, tracemalloc
from dataclasses import dataclass
from typing import NamedTuple

N = 100_000
random.seed(2026)
raw = [(str(random.randint(10_000_000, 1_299_999_999)), random.choice(["Centro","Suba","Kennedy"]),
        "2026-03-14", "D8010", 180000) for _ in range(N)]

@dataclass
class ApptDC:
    document: str; branch: str; date: str; code: str; amount: int

@dataclass(slots=True)
class ApptSlots:
    document: str; branch: str; date: str; code: str; amount: int

class ApptNT(NamedTuple):
    document: str; branch: str; date: str; code: str; amount: int

def build_dict(): return [{"document":d,"branch":b,"date":f,"code":c,"amount":a} for d,b,f,c,a in raw]
def build_tuple(): return [t for t in raw]
def build_dc(): return [ApptDC(*t) for t in raw]
def build_slots(): return [ApptSlots(*t) for t in raw]
def build_nt(): return [ApptNT(*t) for t in raw]

def peak(fn):
    tracemalloc.start(); obj = fn(); _, pk = tracemalloc.get_traced_memory(); tracemalloc.stop()
    return pk/1e6, obj

def access(objs, kind):
    t0=time.perf_counter()
    if kind=="dict": s=sum(o["amount"] for o in objs)
    elif kind=="tuple": s=sum(o[4] for o in objs)
    else: s=sum(o.amount for o in objs)
    return (time.perf_counter()-t0)*1000

for name,fn,kind in [("tuple",build_tuple,"tuple"),("dict",build_dict,"dict"),
                     ("dataclass",build_dc,"attr"),("dataclass(slots)",build_slots,"attr"),
                     ("NamedTuple",build_nt,"attr")]:
    pk, objs = peak(fn)
    times=[access(objs,kind) for _ in range(7)]; times.sort()
    t0=time.perf_counter(); fn(); build_ms=(time.perf_counter()-t0)*1000
    print(f"{name:<18} memoria {pk:7.1f} MB · construir {build_ms:7.0f} ms · acceso {statistics.median(times):6.1f} ms")
