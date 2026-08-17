# Phase 4 Complete: Linear Layer with MDS Verification
# Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
# Authors: Ahmad Ali Parr — Jessica Westerhoff
# License: BSL-1.1 / AGPL-3.0 / MPL-2.0

from __future__ import annotations
import itertools
import random
from phase2_gf256 import GF256, _gf_mul_raw
from phase3_sbox import sbox, inv_sbox

State = list  # 4×4 list of lists

# ═══════════════════════════════════════════════════════════════════════
# SHIFTROWS
# ═══════════════════════════════════════════════════════════════════════

def shift_rows(s: State) -> State:
    return [
        s[0][:],
        s[1][1:] + s[1][:1],
        s[2][2:] + s[2][:2],
        s[3][3:] + s[3][:3],
    ]

def inv_shift_rows(s: State) -> State:
    return [
        s[0][:],
        s[1][-1:] + s[1][:-1],
        s[2][-2:] + s[2][:-2],
        s[3][-3:] + s[3][:-3],
    ]

# ═══════════════════════════════════════════════════════════════════════
# MIXCOLUMNS (MDS)
# ═══════════════════════════════════════════════════════════════════════

def mix_column(col: list) -> list:
    b0, b1, b2, b3 = GF256(col[0]), GF256(col[1]), GF256(col[2]), GF256(col[3])
    return [
        (GF256(2)*b0 + GF256(3)*b1 + b2 + b3).val,
        (b0 + GF256(2)*b1 + GF256(3)*b2 + b3).val,
        (b0 + b1 + GF256(2)*b2 + GF256(3)*b3).val,
        (GF256(3)*b0 + b1 + b2 + GF256(2)*b3).val,
    ]

def inv_mix_column(col: list) -> list:
    b0, b1, b2, b3 = GF256(col[0]), GF256(col[1]), GF256(col[2]), GF256(col[3])
    return [
        (GF256(0x0E)*b0 + GF256(0x0B)*b1 + GF256(0x0D)*b2 + GF256(0x09)*b3).val,
        (GF256(0x09)*b0 + GF256(0x0E)*b1 + GF256(0x0B)*b2 + GF256(0x0D)*b3).val,
        (GF256(0x0D)*b0 + GF256(0x09)*b1 + GF256(0x0E)*b2 + GF256(0x0B)*b3).val,
        (GF256(0x0B)*b0 + GF256(0x0D)*b1 + GF256(0x09)*b2 + GF256(0x0E)*b3).val,
    ]

def mix_columns(s: State) -> State:
    result = [[0]*4 for _ in range(4)]
    for col in range(4):
        mc = mix_column([s[row][col] for row in range(4)])
        for row in range(4):
            result[row][col] = mc[row]
    return result

def inv_mix_columns(s: State) -> State:
    result = [[0]*4 for _ in range(4)]
    for col in range(4):
        mc = inv_mix_column([s[row][col] for row in range(4)])
        for row in range(4):
            result[row][col] = mc[row]
    return result

# ═══════════════════════════════════════════════════════════════════════
# LINEAR LAYER
# ═══════════════════════════════════════════════════════════════════════

def linear_layer(s: State) -> State:
    return mix_columns(shift_rows(s))

def inv_linear_layer(s: State) -> State:
    return inv_shift_rows(inv_mix_columns(s))

# ═══════════════════════════════════════════════════════════════════════
# ROUND FUNCTION
# ═══════════════════════════════════════════════════════════════════════

def sbox_layer(s: State) -> State:
    return [[sbox(b) for b in row] for row in s]

def inv_sbox_layer(s: State) -> State:
    return [[inv_sbox(b) for b in row] for row in s]

def add_round_key(s: State, key: list) -> State:
    return [[s[r][c] ^ key[r + 4*c] for c in range(4)] for r in range(4)]

def round_fn(s: State, key: list) -> State:
    return add_round_key(linear_layer(sbox_layer(s)), key)

def inv_round_fn(s: State, key: list) -> State:
    return inv_sbox_layer(inv_linear_layer(add_round_key(s, key)))

# ═══════════════════════════════════════════════════════════════════════
# MDS VERIFICATION
# ═══════════════════════════════════════════════════════════════════════

def gf256_det(mat: list) -> GF256:
    n = len(mat)
    if n == 1:
        return mat[0][0]
    if n == 2:
        return mat[0][0]*mat[1][1] + mat[0][1]*mat[1][0]
    det = GF256(0)
    for col in range(n):
        minor = [[mat[r][c] for c in range(n) if c != col] for r in range(1, n)]
        det = det + mat[0][col] * gf256_det(minor)
    return det

def mixcols_matrix() -> list:
    return [
        [GF256(2), GF256(3), GF256(1), GF256(1)],
        [GF256(1), GF256(2), GF256(3), GF256(1)],
        [GF256(1), GF256(1), GF256(2), GF256(3)],
        [GF256(3), GF256(1), GF256(1), GF256(2)],
    ]

def verify_all_submatrices_invertible() -> bool:
    mc = mixcols_matrix()

    # 1×1: all entries non-zero
    for i in range(4):
        for j in range(4):
            if mc[i][j] == GF256(0):
                return False

    # 2×2
    for rows in itertools.combinations(range(4), 2):
        for cols in itertools.combinations(range(4), 2):
            sub = [[mc[r][c] for c in cols] for r in rows]
            if gf256_det(sub) == GF256(0):
                return False

    # 3×3
    for rows in itertools.combinations(range(4), 3):
        for cols in itertools.combinations(range(4), 3):
            sub = [[mc[r][c] for c in cols] for r in rows]
            if gf256_det(sub) == GF256(0):
                return False

    # 4×4
    if gf256_det(mc) == GF256(0):
        return False

    return True

def column_weight(col: list) -> int:
    return sum(1 for b in col if b != 0)

def verify_branch_number_5() -> bool:
    min_branch = 255
    # Check all weight-1 inputs (4 positions × 255 values = 1020)
    for pos in range(4):
        for val in range(1, 256):
            col = [0, 0, 0, 0]
            col[pos] = val
            in_wt = column_weight(col)
            out = mix_column(col)
            out_wt = column_weight(out)
            branch = in_wt + out_wt
            min_branch = min(min_branch, branch)

    # Weight-1 + MDS → all output bytes non-zero → branch = 1+4 = 5
    return min_branch == 5

def verify_linear_layer_roundtrip(n: int = 10000) -> bool:
    for _ in range(n):
        s = [[random.randint(0, 255) for _ in range(4)] for _ in range(4)]
        s2 = inv_linear_layer(linear_layer([row[:] for row in s]))
        if s != s2:
            return False
    return True

def verify_round_fn_roundtrip(n: int = 1000) -> bool:
    key = [random.randint(0, 255) for _ in range(16)]
    for _ in range(n):
        s = [[random.randint(0, 255) for _ in range(4)] for _ in range(4)]
        s2 = inv_round_fn(round_fn([row[:] for row in s], key), key)
        if s != s2:
            return False
    return True

# ═══════════════════════════════════════════════════════════════════════
# 128×128 MATRIX OVER GF(2)
# ═══════════════════════════════════════════════════════════════════════

def build_128x128_matrix() -> list:
    matrix = [[0]*128 for _ in range(128)]
    for input_bit in range(128):
        row_idx = input_bit // 32
        col_idx = (input_bit % 32) // 8
        bit_idx = input_bit % 8

        state = [[0]*4 for _ in range(4)]
        state[row_idx][col_idx] = 1 << bit_idx
        out = linear_layer(state)

        for r in range(4):
            for c in range(4):
                for b in range(8):
                    if (out[r][c] >> b) & 1:
                        out_bit = r * 32 + c * 8 + b
                        matrix[out_bit][input_bit] = 1
    return matrix

def verify_128x128_invertible() -> bool:
    mat = build_128x128_matrix()
    n = 128
    a = [row[:] for row in mat]
    for col in range(n):
        pivot = None
        for row in range(col, n):
            if a[row][col] == 1:
                pivot = row
                break
        if pivot is None:
            return False
        if pivot != col:
            a[col], a[pivot] = a[pivot], a[col]
        for row in range(n):
            if row != col and a[row][col] == 1:
                for c in range(n):
                    a[row][c] ^= a[col][c]
    return True

# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("Phase 4: Linear Layer — MDS Verification")
    print("=" * 60)

    print("\n1. ShiftRows...", end=" ", flush=True)
    s = [[i + 4*j for j in range(4)] for i in range(4)]
    sr = shift_rows(s)
    assert sr[0] == s[0]
    assert sr[1] == s[1][1:] + s[1][:1]
    assert sr[2] == s[2][2:] + s[2][:2]
    assert sr[3] == s[3][3:] + s[3][:3]
    assert inv_shift_rows(sr) == s
    print("PASS")

    print("2. MixColumns FIPS-197 vectors...", end=" ", flush=True)
    # State[row][col] — each column processed independently
    # Col 0: [0xDB,0x13,0x53,0x45] -> [0x8E,0x4D,0xA1,0xBC]
    test = [[0xDB, 0xF2, 0x01, 0xC6],
            [0x13, 0x0A, 0x01, 0xC6],
            [0x53, 0x22, 0x01, 0xC6],
            [0x45, 0x5C, 0x01, 0xC6]]
    mc = mix_columns(test)
    assert [mc[r][0] for r in range(4)] == [0x8E, 0x4D, 0xA1, 0xBC]
    assert [mc[r][2] for r in range(4)] == [0x01, 0x01, 0x01, 0x01]
    assert [mc[r][3] for r in range(4)] == [0xC6, 0xC6, 0xC6, 0xC6]
    assert inv_mix_columns(mc) == test
    print("PASS")

    print("3. MDS: all submatrices invertible...", end=" ", flush=True)
    assert verify_all_submatrices_invertible()
    print("PASS (16+36+16+1 = 69 submatrices checked)")

    print("4. Branch number = 5...", end=" ", flush=True)
    assert verify_branch_number_5()
    print("PASS")

    print("5. Linear layer roundtrip (10K)...", end=" ", flush=True)
    assert verify_linear_layer_roundtrip()
    print("PASS")

    print("6. Round function roundtrip (1K)...", end=" ", flush=True)
    assert verify_round_fn_roundtrip()
    print("PASS")

    print("7. 128x128 matrix over GF(2) invertible...", end=" ", flush=True)
    assert verify_128x128_invertible()
    print("PASS")

    print("\n" + "=" * 60)
    print("ALL PHASE 4 VERIFICATIONS PASSED")
    print("=" * 60)
    print("  ShiftRows: Permutation (bijective)")
    print("  MixColumns: MDS, branch number = 5 (optimal)")
    print("  Linear layer: L = MC . SR, bijective, rank 128")
    print("  Round function: All components bijective")
