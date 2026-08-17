// Phase 7 Complete: Complexity Analysis & Conjectures
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff

use std::time::Instant;
use crate::aes128::encrypt;

// ═══════════════════════════════════════════════════════════════════════
// COMPLEXITY MEASURES
// ═══════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone, Copy, PartialEq)]
pub struct Complexity {
    pub time_ops:      u128,
    pub space_bytes:   u128,
    pub circuit_depth: u128,
    pub memory_bits:   u128,
    pub queries:       u128,
}

impl Complexity {
    pub const fn new(
        time_ops: u128, space_bytes: u128,
        circuit_depth: u128, memory_bits: u128, queries: u128,
    ) -> Self {
        Self { time_ops, space_bytes, circuit_depth, memory_bits, queries }
    }

    pub fn security_margin(&self, target: &Complexity) -> f64 {
        target.time_ops as f64 / self.time_ops as f64
    }
}

// ═══════════════════════════════════════════════════════════════════════
// ATTACK COMPLEXITIES
// ═══════════════════════════════════════════════════════════════════════

// 2^128 overflows u128 (max = 2^128-1); use u128::MAX as sentinel for brute-force / groebner
pub const BRUTE_FORCE:   Complexity = Complexity::new(u128::MAX, 0, 0, 0, 0);
pub const BICLIQUE:      Complexity = Complexity::new(1u128 << 97, 1u128 << 40, 0, 1u128 << 50, 0);
// Grover: 2^64 oracle queries; TIME = queries × ~10000 gates ≈ 2^77 — LESS than biclique 2^97
pub const GROVER_AES128: Complexity = Complexity::new(
    (1u128 << 64) * 10_000, 1u128 << 64, 1u128 << 64, 1u128 << 70, 1u128 << 64,
);
// Groebner on full AES > 2^128; represent as u128::MAX (same as brute force)
pub const GROEBNER_FULL_AES: Complexity =
    Complexity::new(u128::MAX, 1u128 << 80, 1u128 << 60, 1u128 << 100, 0);
pub const XSL_ATTACK: Complexity = Complexity::new(1u128 << 100, 1u128 << 60, 0, 1u128 << 70, 0);

// Backward-compat aliases (used by older module references)
pub const BICLIQUE_COMPLEXITY:   Complexity = BICLIQUE;
pub const GROVER_AES128_COST:    Complexity = GROVER_AES128;

pub fn groebner_complexity(rounds: usize) -> Complexity {
    match rounds {
        1 => Complexity::new(1<<20, 1<<10, 1<<5,  1<<15, 0),
        2 => Complexity::new(1<<40, 1<<20, 1<<10, 1<<30, 0),
        3 => Complexity::new(1<<60, 1<<30, 1<<20, 1<<40, 0),
        4 => Complexity::new(1<<80, 1<<40, 1<<30, 1<<50, 0),
        _ => GROEBNER_FULL_AES,
    }
}

// Kept for main.rs backwards compatibility
pub fn estimate_groebner(rounds: usize) -> Complexity { groebner_complexity(rounds) }

// ═══════════════════════════════════════════════════════════════════════
// BENCHMARK
// ═══════════════════════════════════════════════════════════════════════

pub fn benchmark_aes(iterations: usize) -> f64 {
    let key = [0x2b_u8, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
               0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c];
    let pt  = [0x6b_u8, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
               0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a];
    let start = Instant::now();
    for _ in 0..iterations { let _ = encrypt(&key, &pt); }
    start.elapsed().as_nanos() as f64 / iterations as f64
}

pub fn aes_circuit_gates() -> u128 { 10_000 }

pub fn grover_time_complexity() -> u128 {
    GROVER_AES128.queries.saturating_mul(aes_circuit_gates())
}

pub fn verify_complexity_ordering() -> bool {
    // Ordering by TIME: Groebner ≈ Brute > Biclique > Grover(time) > Grover(queries)
    BICLIQUE.time_ops < BRUTE_FORCE.time_ops           // 2^97 < 2^128
        && GROVER_AES128.time_ops < BICLIQUE.time_ops  // 2^77 < 2^97  (Grover time < biclique)
        && GROVER_AES128.queries  < BICLIQUE.time_ops  // 2^64 < 2^97
        && GROEBNER_FULL_AES.time_ops >= BICLIQUE.time_ops // > 2^128 ≥ 2^97
}

// Backward-compat for main.rs
pub fn verify_no_break() -> bool {
    assert!(GROEBNER_FULL_AES.time_ops > BICLIQUE.time_ops);
    true
}

pub fn security_margin(attack: &Complexity, target: &Complexity) -> f64 {
    target.time_ops as f64 / attack.time_ops as f64
}

// ═══════════════════════════════════════════════════════════════════════
// NIST SECURITY LEVELS
// ═══════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum NISTSecurityLevel { Level1, Level3, Level5 }

pub const AES128_NIST_LEVEL:              NISTSecurityLevel = NISTSecurityLevel::Level1;
pub const AES128_QUANTUM_SECURITY_BITS:   u32 = 64;
pub const AES128_CLASSICAL_SECURITY_BITS: u32 = 97;

// ═══════════════════════════════════════════════════════════════════════
// CONJECTURE TRACKING
// ═══════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone, Copy, PartialEq)]
pub enum ConjectureStatus { Unproven, Falsified, Proven }

#[derive(Debug, Clone)]
pub struct Conjecture {
    pub name:                   &'static str,
    pub statement:              &'static str,
    pub status:                 ConjectureStatus,
    pub falsification_criteria: &'static str,
}

pub const CONJECTURES: &[Conjecture] = &[
    Conjecture {
        name:      "No Classical Beats Biclique",
        statement: "No classical attack on AES-128 has complexity < 2^97",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Classical attack with complexity < 2^97",
    },
    Conjecture {
        name:      "Groebner R_NL Hard",
        statement: "Gröbner basis on R_NL system requires > 2^128 operations",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Gröbner basis computation ≤ 2^128",
    },
    Conjecture {
        name:      "No Poly-Time Inversion",
        statement: "No polynomial-time algorithm inverts R_NL",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Poly-time inverter for R_NL",
    },
    Conjecture {
        name:      "Grover Optimal Quantum",
        statement: "Grover's algorithm is optimal quantum attack (2^64 queries)",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Quantum algorithm with < 2^64 queries",
    },
    Conjecture {
        name:      "AES-128 PRP",
        statement: "AES-128 is a pseudorandom permutation",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Distinguisher with non-negligible advantage",
    },
    Conjecture {
        name:      "Related-Key Security",
        statement: "No related-key attacks on AES-128",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Related-key distinguisher",
    },
    Conjecture {
        name:      "R_NL Minimal Degree 254",
        statement: "R_NL polynomial system has minimal degree 254",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Degree < 254 representation found",
    },
    Conjecture {
        name:      "Key Schedule Secure",
        statement: "AES-128 key schedule produces independent round keys",
        status:    ConjectureStatus::Unproven,
        falsification_criteria: "Round key dependency found",
    },
];

// ═══════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_complexity_ordering() {
        assert!(verify_complexity_ordering(), "Complexity ordering violated");
    }

    #[test]
    fn test_biclique_margin() {
        let m = security_margin(&BICLIQUE, &BRUTE_FORCE);
        // 2^128 / 2^97 = 2^31 ≈ 2.147e9; using u128::MAX ≈ 2^128 so margin ≈ 2^31
        assert!(m > 2_f64.powi(30) && m < 2_f64.powi(32),
                "Biclique margin should be ~2^31, got {}", m);
    }

    #[test]
    fn test_grover_vs_biclique() {
        // Grover TIME (2^77) < Biclique (2^97) — quantum attack is faster in wall-clock time
        // but requires 2^64 fault-tolerant qubits which is infeasible classically
        assert!(grover_time_complexity() < BICLIQUE.time_ops,
                "Grover time {} should be < Biclique {}", grover_time_complexity(), BICLIQUE.time_ops);
    }

    #[test]
    fn test_benchmark() {
        let ns = benchmark_aes(1000);
        assert!(ns < 100_000.0, "AES too slow: {} ns/op", ns);
    }

    #[test]
    fn test_groebner_scaling() {
        for r in 1..=4 {
            let c = groebner_complexity(r);
            assert!(c.time_ops > 0);
        }
    }

    #[test]
    fn test_conjecture_status() {
        for c in CONJECTURES {
            assert_eq!(c.status, ConjectureStatus::Unproven,
                       "{} should be Unproven", c.name);
        }
    }

    #[test]
    fn test_ordering_legacy() {
        assert!(BICLIQUE_COMPLEXITY.time_ops < GROEBNER_FULL_AES.time_ops,
                "Biclique {} should be < Groebner {}", BICLIQUE_COMPLEXITY.time_ops, GROEBNER_FULL_AES.time_ops);
        assert!(BICLIQUE_COMPLEXITY.time_ops < BRUTE_FORCE.time_ops);
    }
}
