# AES-256 14-Round TTI Margin

This note extends the Phase 9 AES trail-margin arithmetic to full
14-round AES-256. It does not claim an AES-256 break.

## Model

The extension uses the same conservative active-S-box schedule already used by
Phase 9:

| Rounds | Minimum active S-boxes |
|---:|---:|
| 1 | 1 |
| 2 | 5 |
| 3 | 9 |
| 4 | 25 |
| 5 | 26 |
| 6 | 30 |
| 7 | 34 |
| 8 | 50 |
| 9+ | `50 + 6 * (rounds - 8)` |

Each active AES S-box contributes differential weight 6, because the maximum
AES S-box differential probability is `2^-6`.

## Failure Points

| Threshold | First failing round | Reason |
|---|---:|---|
| Finite 128-bit block codebook | 4 | round 3 weight is `54`, round 4 weight is `150 > 128` |
| AES-256 exhaustive key-search budget | 8 | round 7 weight is `204`, round 8 weight is `300 > 256` |

## Full 14-Round State

For 14 rounds:

- active S-box lower bound: `86`
- differential data exponent: `86 * 6 = 516`
- margin over finite codebook: `516 - 128 = 388` bits
- margin over AES-256 key search: `516 - 256 = 260` bits

Conclusion: under this TTI-style differential/algebraic margin model, the
full 14-round AES-256 attack demand is beyond both the finite-codebook data
budget and the AES-256 exhaustive key-search budget.

## Evidence

- Python executable checker: `python/phase11_aes256_14round.py`
- Rust executable checker: `rust/src/aes256_margin.rs`
- Lean arithmetic theorem file: `lean/Phase11_AES256_14RoundMargin.lean`

Boundary: this is verified arithmetic over stated model constants. It is not a
new cryptanalytic lower bound and does not close the open AES conjectures.

