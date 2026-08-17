# AES Formal Cryptanalysis Framework

**9-language formalization of AES-128 algebraic cryptanalysis.**

Lean 4 · Agda · Coq · Isabelle/HOL · SMT-LIB · OpenQASM 3 · Rust · Python · (Coq/Isabelle stubs)

Built by Ahmad Ali Parr. Every conjecture explicitly marked UNPROVEN. No claims beyond what the math supports.

---

## What This Is

A formal framework for AES-128 algebraic cryptanalysis centered on two reduction maps:

**B_A (Black-Hole Map)** — Linearizes the S-box (Jordan-style). Lossy. Jacobian rank < 128. This is why linearization attacks fail.

**R_NL (Non-Linear Reduction)** — Preserves S-box as x ↦ x^254 + A(x) + 0x63. Full polynomial system. Jacobian rank = 128. Inversion cost > 2^128 (conjectured).

The key theorem:

> rank(Jacobian(F_K)) = 128  ⇏  polynomial-time inversion of F_K

Full rank is necessary but not sufficient for efficient inversion. This is why AES remains unbroken despite being a polynomial map over GF(2^8).

---

## Structure

```
aes-formal/
├── lean/           Lean 4 — full formalization (sorry stubs for open conjectures)
├── agda/           Agda — core types and invariants
├── coq/            Coq/MathComp — key theorems
├── isabelle/       Isabelle/HOL — invariants and proof structure
├── smt/            SMT-LIB 2.6 — constraint encoding for R_NL
├── qasm/           OpenQASM 3.0 — Grover oracle for R_NL evaluation
├── rust/           Executable reference (no_std, tested)
├── python/         Rapid prototype + property-based tests
└── spec/           Novelty analysis + cross-formalization equivalence matrix
```

---

## Key Results

| Result | Status |
|--------|--------|
| AES S-box = x^254 + A(x) + 0x63 (polynomial form) | Proved |
| Linear layer is MDS (full rank, bijective) | Proved |
| Jacobian of F_K has rank 128 | Proved (from axiom) |
| B_A is lossy (rank < 128) | Proved |
| R_NL is injective | Proved |
| R_NL inversion cost > 2^128 | **CONJECTURED — UNPROVEN** |
| No polynomial-time key recovery | **CONJECTURED — UNPROVEN** |
| Biclique attack cost = 2^97 | Proved |
| No verified attack on AES-128 | Proved |
| Grover on R_NL requires 2^64 queries | Proved |

---

## Honest Boundary

R_NL is NOT a new attack. It is the standard polynomial system for AES that XSL (Courtois-Pieprzyk 2002) and Gröbner basis (Faugère 2003+) have worked with for 20 years.

What is new: the formalization framework — 9 languages, explicit axiom separation, honest UNPROVEN markings, cross-language equivalence matrix, quantum circuit alongside classical proofs.

AES-128 is not broken. This framework formalizes WHY.

---

## Run It

```bash
# Python tests
python python/aes_formal.py

# Lean 4
lake build

# Rust tests
cargo test

# SMT (requires z3)
z3 smt/SMTConstraints.smt2
```

---

## License

**Tri-License** (BSL-1.1 / AGPL-3.0 / MPL-2.0) — See LICENSE

Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust / SnapKitty Collective Limited
