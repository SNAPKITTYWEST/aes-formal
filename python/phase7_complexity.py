"""
Phase 7 Complete: Complexity Analysis & Conjectures
Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
Authors: Ahmad Ali Parr — Jessica Westerhoff
"""

from __future__ import annotations
from dataclasses import dataclass
from typing import List, Optional, Callable
import time

# ═══════════════════════════════════════════════════════════════════════
# COMPLEXITY MEASURES
# ═══════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class Complexity:
    time_ops:      int
    space_bytes:   int
    circuit_depth: int
    memory_bits:   int
    queries:       int

    def security_margin(self, target: Complexity) -> float:
        return target.time_ops / self.time_ops

    def __gt__(self, other: Complexity) -> bool:
        return self.time_ops > other.time_ops

    def __lt__(self, other: Complexity) -> bool:
        return self.time_ops < other.time_ops

    def __le__(self, other: Complexity) -> bool:
        return self.time_ops <= other.time_ops

    def __ge__(self, other: Complexity) -> bool:
        return self.time_ops >= other.time_ops

# ═══════════════════════════════════════════════════════════════════════
# ATTACK COMPLEXITIES
# ═══════════════════════════════════════════════════════════════════════

BRUTE_FORCE        = Complexity(2**128, 0,      0,      0,       0)
BICLIQUE           = Complexity(2**97,  2**40,  0,      2**50,   0)
GROVER_AES128      = Complexity(2**64 * 10000, 2**64,  2**64,  2**70,   2**64)
GROEBNER_FULL_AES  = Complexity(2**128 + 1,    2**80,  2**60,  2**100,  0)
XSL_ATTACK         = Complexity(2**100, 2**60,  0,      2**70,   0)


def groebner_complexity(rounds: int) -> Complexity:
    """Gröbner basis complexity for reduced-round AES."""
    table = {
        1: Complexity(2**20, 2**10, 2**5,  2**15, 0),
        2: Complexity(2**40, 2**20, 2**10, 2**30, 0),
        3: Complexity(2**60, 2**30, 2**20, 2**40, 0),
        4: Complexity(2**80, 2**40, 2**30, 2**50, 0),
    }
    return table.get(rounds, GROEBNER_FULL_AES)


# ═══════════════════════════════════════════════════════════════════════
# COMPLEXITY VERIFICATION
# ═══════════════════════════════════════════════════════════════════════

def verify_complexity_ordering() -> bool:
    # Ordering by TIME: Groebner >= Brute > Biclique > Grover(time) > Grover(queries)
    checks = [
        ("Brute > Biclique",           BRUTE_FORCE > BICLIQUE),
        ("Biclique > Grover(time)",    BICLIQUE > GROVER_AES128),        # 2^97 > 2^77
        ("Grover queries < Biclique",  GROVER_AES128.queries < BICLIQUE.time_ops),
        ("Grover queries < Brute",     GROVER_AES128.queries < BRUTE_FORCE.time_ops),
        ("Groebner > Biclique",        GROEBNER_FULL_AES > BICLIQUE),
        ("XSL > Biclique",             XSL_ATTACK > BICLIQUE),
    ]
    ok = True
    for name, result in checks:
        if not result:
            print(f"  FAIL: {name}")
            ok = False
    return ok


def security_margin(attack: Complexity, target: Complexity) -> float:
    return target.time_ops / attack.time_ops


# ═══════════════════════════════════════════════════════════════════════
# CONJECTURES
# ═══════════════════════════════════════════════════════════════════════

@dataclass(frozen=True)
class Conjecture:
    name:                   str
    statement:              str
    status:                 str  # "Unproven" | "Falsified" | "Proven"
    falsification_criteria: str


CONJECTURES: List[Conjecture] = [
    Conjecture(
        "No Classical Beats Biclique",
        "No classical attack on AES-128 has complexity < 2^97",
        "Unproven",
        "Classical attack with complexity < 2^97",
    ),
    Conjecture(
        "Groebner R_NL Hard",
        "Gröbner basis on R_NL system requires > 2^128 operations",
        "Unproven",
        "Gröbner basis computation ≤ 2^128",
    ),
    Conjecture(
        "No Poly-Time Inversion",
        "No polynomial-time algorithm inverts R_NL",
        "Unproven",
        "Poly-time inverter for R_NL",
    ),
    Conjecture(
        "Grover Optimal Quantum",
        "Grover's algorithm is optimal quantum attack (2^64 queries)",
        "Unproven",
        "Quantum algorithm with < 2^64 queries",
    ),
    Conjecture(
        "AES-128 PRP",
        "AES-128 is a pseudorandom permutation",
        "Unproven",
        "Distinguisher with non-negligible advantage",
    ),
    Conjecture(
        "Related-Key Security",
        "No related-key attacks on AES-128",
        "Unproven",
        "Related-key distinguisher",
    ),
    Conjecture(
        "R_NL Minimal Degree 254",
        "R_NL polynomial system has minimal degree 254",
        "Unproven",
        "Degree < 254 representation found",
    ),
    Conjecture(
        "Key Schedule Secure",
        "AES-128 key schedule produces independent round keys",
        "Unproven",
        "Round key dependency found",
    ),
]


# ═══════════════════════════════════════════════════════════════════════
# FALSIFICATION STRUCTURES
# ═══════════════════════════════════════════════════════════════════════

@dataclass
class Falsification:
    conjecture_name: str
    evidence:        str
    complexity:      Complexity
    verified:        bool


# ═══════════════════════════════════════════════════════════════════════
# BENCHMARK
# ═══════════════════════════════════════════════════════════════════════

def benchmark_aes(iterations: int = 10_000) -> float:
    """Returns ns/op for AES-128 encryption."""
    try:
        from phase5_aes128 import encrypt
    except ImportError:
        return float("nan")

    key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
           0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]
    pt  = [0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
           0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a]

    start = time.perf_counter_ns()
    for _ in range(iterations):
        encrypt(key, pt)
    return (time.perf_counter_ns() - start) / iterations


def aes_circuit_gates() -> int:
    return 10_000  # rough gate count per AES-128 evaluation


def grover_time_complexity() -> int:
    return GROVER_AES128.queries * aes_circuit_gates()


# ═══════════════════════════════════════════════════════════════════════
# POST-QUANTUM
# ═══════════════════════════════════════════════════════════════════════

class NISTSecurityLevel:
    LEVEL1 = "Level1 (AES-128 equivalent)"
    LEVEL3 = "Level3 (AES-192 equivalent)"
    LEVEL5 = "Level5 (AES-256 equivalent)"


AES128_NIST_LEVEL              = NISTSecurityLevel.LEVEL1
AES128_QUANTUM_SECURITY_BITS   = 64
AES128_CLASSICAL_SECURITY_BITS = 97


# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    W = 70
    print("=" * W)
    print("PHASE 7: COMPLEXITY ANALYSIS & CONJECTURES")
    print("=" * W)

    print("\n1. Attack Complexities:")
    print(f"   Brute Force : 2^128")
    print(f"   Biclique    : 2^97")
    print(f"   Grover      : 2^64 queries  |  2^64 * 10000 ~= 2^77 time")
    print(f"   Gröbner     : > 2^128 (conjectured)")
    print(f"   XSL         : 2^100")

    print("\n2. Complexity Ordering:")
    ok = verify_complexity_ordering()
    if ok:
        print("   PASS — all relationships verified")
    else:
        print("   SOME CHECKS FAILED")

    print("\n3. Security Margins:")
    m_biclique = security_margin(BICLIQUE, BRUTE_FORCE)
    m_grover   = security_margin(GROVER_AES128, BRUTE_FORCE)
    print(f"   Biclique vs Brute Force : {m_biclique:.3e} = 2^31")
    print(f"   Grover(time) vs Brute   : {m_grover:.3e}")

    print("\n4. Conjectures (all UNPROVEN):")
    for c in CONJECTURES:
        print(f"   [{c.status:8}] {c.name}")
        print(f"             Falsified by: {c.falsification_criteria}")

    print("\n5. Benchmark:")
    ns = benchmark_aes(10_000)
    if ns != float("nan"):
        print(f"   AES-128: {ns:.2f} ns/op")
    else:
        print("   (phase5_aes128 not available)")

    print("\n6. Grover vs Biclique:")
    gt = grover_time_complexity()
    print(f"   Grover time : 2^64 × {aes_circuit_gates()} ≈ 2^77")
    print(f"   Biclique    : 2^97")
    print(f"   Grover time (2^77) < Biclique (2^97): {gt < BICLIQUE.time_ops}  (Grover is FASTER in ops, but requires fault-tolerant quantum hardware)")

    print("\n7. NIST Post-Quantum Security:")
    print(f"   AES-128 NIST level       : {AES128_NIST_LEVEL}")
    print(f"   Quantum security (Grover): {AES128_QUANTUM_SECURITY_BITS} bits")
    print(f"   Classical security       : {AES128_CLASSICAL_SECURITY_BITS} bits (biclique)")

    print("\n" + "=" * W)
    print("PHASE 7 COMPLETE")
    print("=" * W)
