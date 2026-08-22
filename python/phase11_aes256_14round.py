"""
Phase 11: AES-256 14-round TTI attack margin analysis.

This file does not claim an AES-256 break. It encodes the arithmetic
failure point for a TTI-style differential/algebraic attack model using
the same conservative active-S-box schedule already used by Phase 9:

    rounds 1..8:  1, 5, 9, 25, 26, 30, 34, 50
    rounds >= 9:  50 + 6 * (rounds - 8)

Each active AES S-box contributes differential weight 6, because the
maximum S-box differential probability is 2^-6.
"""

from __future__ import annotations

import sys
from dataclasses import dataclass
from typing import List

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

AES_BLOCK_BITS = 128
AES256_KEY_BITS = 256
AES256_ROUNDS = 14
SBOX_DIFF_WEIGHT_BITS = 6


@dataclass(frozen=True)
class RoundMargin:
    rounds: int
    min_active_sboxes: int
    differential_weight_bits: int
    exceeds_codebook: bool
    exceeds_aes256_key_search: bool


@dataclass(frozen=True)
class AttackFailure:
    first_codebook_failure_round: int
    first_key_search_failure_round: int
    full_round_margin: RoundMargin
    codebook_margin_bits: int
    key_search_margin_bits: int
    status: str


def min_active_sboxes(rounds: int) -> int:
    """Conservative AES active-S-box lower bound used for margin checks."""
    if rounds < 0:
        raise ValueError("round count must be non-negative")

    table = {
        0: 0,
        1: 1,
        2: 5,
        3: 9,
        4: 25,
        5: 26,
        6: 30,
        7: 34,
        8: 50,
    }
    if rounds in table:
        return table[rounds]
    return 50 + 6 * (rounds - 8)


def round_margin(rounds: int) -> RoundMargin:
    active = min_active_sboxes(rounds)
    weight = active * SBOX_DIFF_WEIGHT_BITS
    return RoundMargin(
        rounds=rounds,
        min_active_sboxes=active,
        differential_weight_bits=weight,
        exceeds_codebook=weight > AES_BLOCK_BITS,
        exceeds_aes256_key_search=weight > AES256_KEY_BITS,
    )


def first_failure_round(limit_bits: int, max_rounds: int = AES256_ROUNDS) -> int:
    for rounds in range(1, max_rounds + 1):
        if round_margin(rounds).differential_weight_bits > limit_bits:
            return rounds
    raise AssertionError(f"no failure within {max_rounds} rounds for limit 2^{limit_bits}")


def analyze_tti_aes256_14round() -> AttackFailure:
    full = round_margin(AES256_ROUNDS)
    codebook_failure = first_failure_round(AES_BLOCK_BITS)
    key_failure = first_failure_round(AES256_KEY_BITS)
    return AttackFailure(
        first_codebook_failure_round=codebook_failure,
        first_key_search_failure_round=key_failure,
        full_round_margin=full,
        codebook_margin_bits=full.differential_weight_bits - AES_BLOCK_BITS,
        key_search_margin_bits=full.differential_weight_bits - AES256_KEY_BITS,
        status="TTI attack fails: full 14-round differential data exponent exceeds both finite-codebook and AES-256 key-search budgets.",
    )


def verify_aes256_14round_margin() -> List[tuple[str, bool, str]]:
    result = analyze_tti_aes256_14round()
    full = result.full_round_margin
    checks = [
        (
            "14-round active S-box lower bound",
            full.min_active_sboxes == 86,
            f"active={full.min_active_sboxes}; expected 86",
        ),
        (
            "14-round differential data exponent",
            full.differential_weight_bits == 516,
            f"weight={full.differential_weight_bits}; expected 86*6=516",
        ),
        (
            "first finite-codebook failure",
            result.first_codebook_failure_round == 4,
            f"first round with weight > 128 is {result.first_codebook_failure_round}",
        ),
        (
            "first AES-256 key-search failure",
            result.first_key_search_failure_round == 8,
            f"first round with weight > 256 is {result.first_key_search_failure_round}",
        ),
        (
            "full 14-round codebook margin",
            result.codebook_margin_bits == 388,
            f"516 - 128 = {result.codebook_margin_bits}",
        ),
        (
            "full 14-round AES-256 key margin",
            result.key_search_margin_bits == 260,
            f"516 - 256 = {result.key_search_margin_bits}",
        ),
    ]
    return checks


def print_report() -> None:
    W = 78
    result = analyze_tti_aes256_14round()

    print("=" * W)
    print("PHASE 11: AES-256 14-ROUND TTI ATTACK MARGIN")
    print("=" * W)
    print("Scope: arithmetic margin model, not an AES-256 break.")
    print()
    print(f"{'Rounds':>6}  {'Active S-boxes':>15}  {'Data exponent':>15}  {'>2^128':>8}  {'>2^256':>8}")
    print(f"{'-'*6}  {'-'*15}  {'-'*15}  {'-'*8}  {'-'*8}")
    for rounds in range(1, AES256_ROUNDS + 1):
        m = round_margin(rounds)
        print(
            f"{rounds:>6}  {m.min_active_sboxes:>15}  "
            f"2^{m.differential_weight_bits:<12}  "
            f"{str(m.exceeds_codebook):>8}  {str(m.exceeds_aes256_key_search):>8}"
        )

    full = result.full_round_margin
    print()
    print("Failure points:")
    print(f"  finite-codebook data budget (>2^128): round {result.first_codebook_failure_round}")
    print(f"  AES-256 key-search budget (>2^256):   round {result.first_key_search_failure_round}")
    print()
    print("Full 14-round margin:")
    print(f"  active S-box lower bound: {full.min_active_sboxes}")
    print(f"  differential data cost:   2^{full.differential_weight_bits}")
    print(f"  margin over 2^128 data:   +{result.codebook_margin_bits} bits")
    print(f"  margin over 2^256 keys:   +{result.key_search_margin_bits} bits")
    print()
    print(result.status)
    print("=" * W)

    checks = verify_aes256_14round_margin()
    for name, passed, detail in checks:
        tag = "PASS" if passed else "FAIL"
        print(f"[{tag}] {name}: {detail}")
    if not all(passed for _, passed, _ in checks):
        raise SystemExit(1)


if __name__ == "__main__":
    print_report()

