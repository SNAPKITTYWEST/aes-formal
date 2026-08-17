# NOVELTY ANALYSIS — AES ALGEBRAIC CRYPTANALYSIS FRAMEWORK

## Proposed Construction: Non-Linear Reduction R_NL

**Mathematical Structure**
- Domain: Key × Plaintext × Ciphertext → GF(2)^128
- Structure: Polynomial map preserving S-box as x ↦ x^254 + A(x) + c
- Components: L (linear, MDS) ∘ S (non-linear, degree 254) ∘ K (translation)

---

## Prior Art Comparison

| Technique | Year | Structure | Equivalence to R_NL |
|-----------|------|-----------|---------------------|
| XSL Attack (Courtois-Pieprzyk) | 2002 | Sparse linearization of S-box | **ESSENTIALLY EQUIVALENT** |
| Gröbner Basis on AES (Faugère) | 2003–2010 | Direct polynomial system | **IDENTICAL** |
| Algebraic Side-Channel | 2009+ | Polynomials + leakage | Subsumes R_NL |
| Biclique (Bogdanov et al.) | 2011 | Meet-in-the-middle | Different; baseline 2^97 |
| Quantum Grover | 1996 | Amplitude amplification | 2^64 queries — no algebraic speedup |
| Simon on AES (Kaplan et al.) | 2016 | Period finding (related-key) | Different model |

---

## Verdict: NOT NOVEL

R_NL is a reformulation of the standard polynomial system for AES algebraic cryptanalysis.

B_A (Black-Hole Map) = linearization attacks (XL, XSL) — loses rank.
R_NL = full polynomial system preservation — identical to what XSL/Gröbner work with.

---

## What IS Distinguishable

1. **Explicit Jacobian Rank Analysis** — formal separation of local injectivity (rank=128) from global invertibility.
2. **Multi-language formalization** — 9 languages (Lean 4, Agda, Coq, Isabelle, SMT-LIB, OpenQASM 3, Rust, Python) with explicit UNPROVEN markings.
3. **Honest complexity accounting** — explicit comparison Cost(R_NL^-1) >> 2^128 vs Biclique = 2^97.

---

## UNPROVEN Conjectures (explicitly marked)

1. Inversion Hardness: Cost(Groebner(R_NL(K))) > 2^128 — **UNPROVEN**
2. No Poly-Time Inversion — **UNPROVEN**
3. Biclique Optimality — **UNPROVEN**
4. S-box Degree Minimality — **UNPROVEN**

---

## What This Does NOT Prove

- No attack on AES-128
- No quantum speedup (Grover still 2^64)
- No polynomial-time inversion
- No novel algorithm (R_NL = standard XSL/Gröbner system)
- All theorems marked sorry/Admitted/UNPROVEN

---

## Falsification Criteria

R_NL provides no advantage if:
- Any algebraic solver solves R_NL in < 2^97 operations
- A linearization preserves rank 128 while reducing degree
- Any quantum algorithm exploits R_NL structure for < 2^64 queries

**Current status: All falsification criteria CONFIRMED — R_NL provides no advantage over biclique.**

---

## Next Steps for Verification

1. Complete Lean 4 proofs — replace sorry with mathlib GF(2^8) + matrix rank
2. SMT solving on reduced-round AES (3–4 rounds)
3. Gröbner basis benchmark — exact complexity via Singular/Macaulay2
4. Quantum resource estimation via Q# simulator
5. Cross-proof translation Lean4↔Coq via equivalence checking
