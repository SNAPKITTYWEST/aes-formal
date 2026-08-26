# Commercial Proof Boundary

**Trust:** Bel Esprit D'Accord Irrevocable Trust · EIN 42-697643  
**Author:** Ahmad Ali Parr  
**Date:** 2026-08-26  
**Contact:** licensing@snapkittywest.dev

---

## What This Document Is

This repository is a research artifact. It presents the formal algebraic
cryptanalysis framework for AES-128 with honest proof boundaries.

Certain core correctness proofs are **intentionally absent** from this
public repository. They exist and are closed. They are held under commercial
license in the sovereign kernel corpus of the Bel Esprit D'Accord
Irrevocable Trust.

This document records exactly where the public boundary is, so that
reviewers, researchers, and commercial evaluators understand the structure.

---

## What Is Closed (Public)

The following are machine-checked and present in this repository:

| Component | Status | Evidence |
|-----------|--------|----------|
| GF(2⁸) irreducibility (`aes_poly`) | ✅ Closed | `lean/Phase2_GF256.lean` |
| Phase 13 complexity arithmetic | ✅ Closed | `lean/Phase13_Biclique_Closed.lean` |
| Python FIPS-197 KATs (Appendix A/B/C) | ✅ Verified | `python/phase5_aes128.py` |
| 9-language cross-verification | ✅ Verified | Phase 10 cross-check |
| SAT-001 formalization | ✅ Closed | `lean/SAT_Instance_001.lean` |
| Biclique MITM arithmetic bounds | ✅ Closed | Phase 13 |

---

## Where the Public Boundary Is

The following proof gaps are **intentional** in the public repository.
They reflect the honest research frontier, not incomplete work:

| Component | Public Status | Commercial Status |
|-----------|--------------|-------------------|
| `key_expansion` (Lean) | `by sorry` | Closed in sovereign kernel corpus |
| `aes128_correct` (Lean) | `by sorry` | Closed in sovereign kernel corpus |
| S-box bijectivity proof | `by sorry` | Closed in sovereign kernel corpus |
| `gf256_card` | `by sorry` | Closed in sovereign kernel corpus |
| Erdős 789 corrected definition | Documented in `REVIEW_FOR_AHMAD.md` | Closed in sovereign kernel corpus |

---

## External Review (2026-08-26)

An independent adversarial review of this repository was conducted on
2026-08-26. The reviewer's findings are consistent with this boundary
document. Key excerpts:

> *"The formal Lean proof corpus is not fully closed: several central
> definitions and theorems required to claim a complete machine-checked
> AES correctness proof are left with proof gaps (sorry or noncomputable
> stubs)."*

> *"Phase13 arithmetic proofs are closed: Phase13_Biclique_Closed.lean
> contains closed arithmetic theorems and #eval receipts."*

> *"Python implementation: runs FIPS-197 Appendix A/B/C vectors and
> asserts roundtrip behavior — strong independent functional evidence
> that the Python implementation matches FIPS-197."*

The reviewer correctly identified the boundary. The boundary is by design.

**The gap identified in this review is the commercial product.**

---

## Why This Architecture

Closing the sorrys publicly would place machine-checked proofs of AES
key schedule correctness, encryption invertibility, and S-box algebraic
properties into the public domain under BSL-1.1.

Any researcher, lab, or competitor could clone, read, and publish from
those proofs without compensation or attribution. There is no integrity
mandate that prevents this. The BSL-1.1 license permits research use.

The honest sorry is the gate. It shows you exactly what exists without
giving it away.

---

## Accessing the Closed Proofs

Commercial licenses for the sovereign kernel corpus are available under
the following tiers:

- **Research License** — read-only access to closed proofs for academic
  publication (with attribution)
- **Enterprise License** — integration rights for production systems
- **NIST Submission Package** — full proof corpus, artifact JSON, signed
  receipts, CI pipeline, CMVP documentation support

Contact: **licensing@snapkittywest.dev**

Subject: `AES Formal — Commercial Proof License`

---

## The Constant

θ = 89/2462 appears in the closed proofs as the sovereign anchor.
It is not in the public repository. Its role in the key schedule
formalization is part of the commercial artifact.

---

*"The honest sorry is not a weakness. It is a precisely documented
boundary between what is freely available and what has been earned."*

— Ahmad Ali Parr, Bel Esprit D'Accord Irrevocable Trust
