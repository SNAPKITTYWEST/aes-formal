# Phase 3 Complete: S-box Polynomial with Full Affine Transform
# Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
# Authors: Ahmad Ali Parr — Jessica Westerhoff
# License: BSL-1.1 / AGPL-3.0 / MPL-2.0

from __future__ import annotations
import sys
from phase2_gf256 import GF256, _gf_mul_raw, INV_TABLE

# ═══════════════════════════════════════════════════════════════════════
# AFFINE TRANSFORMATION
# ═══════════════════════════════════════════════════════════════════════

# AES affine matrix rows (each byte = row, LSB = column 0)
AES_AFFINE = [0xF1, 0xE3, 0xC7, 0x8F, 0x1F, 0x3E, 0x7C, 0xF8]

# Inverse affine matrix
AES_INV_AFFINE = [0xA4, 0x49, 0x92, 0x25, 0x4A, 0x94, 0x29, 0x52]

AFFINE_CONST = 0x63


def gf2_mat_vec(matrix: list[int], x: int) -> int:
    result = 0
    for i in range(8):
        dot = bin(matrix[i] & x).count('1') & 1
        result |= dot << i
    return result


def affine_transform(x: int) -> int:
    return gf2_mat_vec(AES_AFFINE, x) ^ AFFINE_CONST


def inv_affine_transform(y: int) -> int:
    return gf2_mat_vec(AES_INV_AFFINE, y ^ AFFINE_CONST)


# ═══════════════════════════════════════════════════════════════════════
# S-BOX POLYNOMIAL: S(x) = A(x⁻¹) for x≠0, S(0) = 0x63
# ═══════════════════════════════════════════════════════════════════════

def sbox(x: int) -> int:
    if x == 0:
        return AFFINE_CONST
    return affine_transform(INV_TABLE[x])


def inv_sbox(y: int) -> int:
    if y == AFFINE_CONST:
        return 0
    pre = inv_affine_transform(y)
    return INV_TABLE[pre] if pre != 0 else 0


# Precompute full table
SBOX_TABLE = [sbox(i) for i in range(256)]
INV_SBOX_TABLE = [inv_sbox(i) for i in range(256)]


# ═══════════════════════════════════════════════════════════════════════
# EXHAUSTIVE VERIFICATION
# ═══════════════════════════════════════════════════════════════════════

def verify_fips197_vectors() -> bool:
    vectors = {
        0x00: 0x63, 0x01: 0x7C, 0x02: 0x77, 0x03: 0x7B,
        0x04: 0xF2, 0x05: 0x6B, 0x06: 0x6F, 0x07: 0xC5,
        0x08: 0x30, 0x09: 0x01, 0x0A: 0x67, 0x0B: 0x2B,
        0x0C: 0xFE, 0x0D: 0xD7, 0x0E: 0xAB, 0x0F: 0x76,
        0x10: 0xCA, 0x53: 0xED, 0xFF: 0x16, 0xFE: 0xBB,
    }
    for inp, expected in vectors.items():
        actual = sbox(inp)
        if actual != expected:
            print(f"FAIL: S(0x{inp:02X}) = 0x{actual:02X}, expected 0x{expected:02X}")
            return False
    return True


def verify_bijection() -> bool:
    seen = [False] * 256
    for i in range(256):
        out = sbox(i)
        if seen[out]:
            return False
        seen[out] = True
    return len(set(SBOX_TABLE)) == 256


def verify_no_fixed_points() -> bool:
    for i in range(256):
        if sbox(i) == i:
            return False
    return True


def verify_inv_roundtrip() -> bool:
    for i in range(256):
        if inv_sbox(sbox(i)) != i:
            return False
        if sbox(inv_sbox(i)) != i:
            return False
    return True


def verify_affine_roundtrip() -> bool:
    for i in range(256):
        if inv_affine_transform(affine_transform(i)) != i:
            return False
        if affine_transform(inv_affine_transform(i)) != i:
            return False
    return True


# ═══════════════════════════════════════════════════════════════════════
# DIFFERENTIAL ANALYSIS
# ═══════════════════════════════════════════════════════════════════════

def compute_ddt() -> list[list[int]]:
    ddt = [[0] * 256 for _ in range(256)]
    for dx in range(1, 256):
        for x in range(256):
            dy = sbox(x ^ dx) ^ sbox(x)
            ddt[dx][dy] += 1
    return ddt


def verify_max_differential() -> bool:
    ddt = compute_ddt()
    max_val = max(max(row) for row in ddt[1:])
    return max_val == 4


# ═══════════════════════════════════════════════════════════════════════
# LINEAR ANALYSIS
# ═══════════════════════════════════════════════════════════════════════

def parity8(x: int) -> int:
    x ^= x >> 4
    x ^= x >> 2
    x ^= x >> 1
    return x & 1


def compute_lat() -> list[list[int]]:
    lat = [[0] * 256 for _ in range(256)]
    for a in range(256):
        for b in range(256):
            count = 0
            for x in range(256):
                p = parity8(a & x) ^ parity8(b & sbox(x))
                if p == 0:
                    count += 1
            lat[a][b] = count - 128
    return lat


def verify_max_linear_bias() -> bool:
    lat = compute_lat()
    max_bias = 0
    for a in range(256):
        for b in range(256):
            if a == 0 and b == 0:
                continue
            bias = abs(lat[a][b])
            if bias > max_bias:
                max_bias = bias
    return max_bias == 16


# ═══════════════════════════════════════════════════════════════════════
# ALGEBRAIC DEGREE (ANF via Mobius transform)
# ═══════════════════════════════════════════════════════════════════════

def compute_algebraic_degree() -> list[int]:
    degrees = []
    for bit in range(8):
        truth_table = [(sbox(x) >> bit) & 1 for x in range(256)]
        anf = truth_table[:]
        for i in range(8):
            for mask in range(256):
                if mask & (1 << i):
                    anf[mask] ^= anf[mask ^ (1 << i)]
        max_deg = 0
        for mask, coeff in enumerate(anf):
            if coeff:
                deg = bin(mask).count('1')
                if deg > max_deg:
                    max_deg = deg
        degrees.append(max_deg)
    return degrees


def verify_algebraic_degree() -> bool:
    degrees = compute_algebraic_degree()
    return all(d == 7 for d in degrees)


# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("Phase 3: S-box Polynomial — Full Affine Transform")
    print("=" * 60)

    print("Affine roundtrip...", end=" ", flush=True)
    assert verify_affine_roundtrip(); print("PASS")

    print("FIPS-197 test vectors...", end=" ", flush=True)
    assert verify_fips197_vectors(); print("PASS")

    print("Bijection (permutation)...", end=" ", flush=True)
    assert verify_bijection(); print("PASS")

    print("No fixed points...", end=" ", flush=True)
    assert verify_no_fixed_points(); print("PASS")

    print("Inverse roundtrip...", end=" ", flush=True)
    assert verify_inv_roundtrip(); print("PASS")

    print("Algebraic degree = 7...", end=" ", flush=True)
    assert verify_algebraic_degree(); print("PASS")

    print("Max differential = 4...", end=" ", flush=True)
    assert verify_max_differential(); print("PASS")

    print("\nMax linear bias (this takes ~30s)...", end=" ", flush=True)
    assert verify_max_linear_bias(); print("PASS")

    print("\n" + "=" * 60)
    print("ALL PHASE 3 VERIFICATIONS PASSED")
    print("S-box properties confirmed:")
    print("  Bijection:                 YES")
    print("  Fixed points:              NONE")
    print("  Differential uniformity:   4 (optimal)")
    print("  Max linear bias:           16 (optimal)")
    print("  Algebraic degree per bit:  7 (max = 254 overall)")
    print("  FIPS-197 compliant:        YES")
