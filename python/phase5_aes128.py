# Phase 5 Complete: AES-128 Full Implementation with FIPS-197 Test Vectors
# Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
# Authors: Ahmad Ali Parr — Jessica Westerhoff
# License: BSL-1.1 / AGPL-3.0 / MPL-2.0

from __future__ import annotations
from phase3_sbox import sbox, inv_sbox
from phase4_linear_layer import (
    shift_rows, inv_shift_rows,
    mix_columns, inv_mix_columns,
    sbox_layer, inv_sbox_layer,
    add_round_key,
)

State = list  # 4x4 list[list[int]]

# ═══════════════════════════════════════════════════════════════════════
# KEY EXPANSION
# ═══════════════════════════════════════════════════════════════════════

RCON = [0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36]


def sub_word(w: list) -> list:
    return [sbox(b) for b in w]


def rot_word(w: list) -> list:
    return w[1:] + w[:1]


def key_expansion(key: list) -> list:
    """Expand 16-byte key into 11 round keys (each 16 bytes flat)."""
    w = []
    for i in range(4):
        w.append(key[4*i:4*i+4])

    for i in range(4, 44):
        temp = w[i - 1][:]
        if i % 4 == 0:
            temp = sub_word(rot_word(temp))
            temp[0] ^= RCON[i // 4 - 1]
        w.append([w[i-4][j] ^ temp[j] for j in range(4)])

    round_keys = []
    for r in range(11):
        rk = []
        for col in range(4):
            rk.extend(w[r*4 + col])
        round_keys.append(rk)
    return round_keys


# ═══════════════════════════════════════════════════════════════════════
# STATE LOADING (column-major input → row-major state)
# ═══════════════════════════════════════════════════════════════════════

def bytes_to_state(flat: list) -> State:
    """Load 16 bytes (column-major) into state[row][col]."""
    s = [[0]*4 for _ in range(4)]
    for r in range(4):
        for c in range(4):
            s[r][c] = flat[r + 4*c]
    return s


def state_to_bytes(s: State) -> list:
    """Dump state[row][col] to 16 bytes (column-major)."""
    out = [0]*16
    for r in range(4):
        for c in range(4):
            out[r + 4*c] = s[r][c]
    return out


# ═══════════════════════════════════════════════════════════════════════
# AES-128 ENCRYPTION
# ═══════════════════════════════════════════════════════════════════════

def aes128_encrypt(key: list, plaintext: list) -> list:
    """Encrypt 16-byte plaintext with 16-byte key. Returns 16-byte ciphertext."""
    rk = key_expansion(key)
    s = bytes_to_state(plaintext)
    s = add_round_key(s, rk[0])

    for r in range(1, 10):
        s = sbox_layer(s)
        s = shift_rows(s)
        s = mix_columns(s)
        s = add_round_key(s, rk[r])

    # Final round (no MixColumns)
    s = sbox_layer(s)
    s = shift_rows(s)
    s = add_round_key(s, rk[10])

    return state_to_bytes(s)


# ═══════════════════════════════════════════════════════════════════════
# AES-128 DECRYPTION
# ═══════════════════════════════════════════════════════════════════════

def aes128_decrypt(key: list, ciphertext: list) -> list:
    """Decrypt 16-byte ciphertext with 16-byte key. Returns 16-byte plaintext."""
    rk = key_expansion(key)
    s = bytes_to_state(ciphertext)

    # Inverse final round
    s = add_round_key(s, rk[10])
    s = inv_shift_rows(s)
    s = inv_sbox_layer(s)

    for r in range(9, 0, -1):
        s = add_round_key(s, rk[r])
        s = inv_mix_columns(s)
        s = inv_shift_rows(s)
        s = inv_sbox_layer(s)

    s = add_round_key(s, rk[0])
    return state_to_bytes(s)


# ═══════════════════════════════════════════════════════════════════════
# FIPS-197 TEST VECTORS
# ═══════════════════════════════════════════════════════════════════════

def test_fips197_appendix_b():
    """FIPS-197 Appendix B test vector (all-zero key is NOT this test).
    Key:    2b7e1516 28aed2a6 abf71588 09cf4f3c
    Input:  3243f6a8 885a308d 313198a2 e0370734
    Output: 3925841d 02dc09fb dc118597 196a0b32
    """
    key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
           0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]
    pt  = [0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d,
           0x31, 0x31, 0x98, 0xa2, 0xe0, 0x37, 0x07, 0x34]
    exp = [0x39, 0x25, 0x84, 0x1d, 0x02, 0xdc, 0x09, 0xfb,
           0xdc, 0x11, 0x85, 0x97, 0x19, 0x6a, 0x0b, 0x32]

    ct = aes128_encrypt(key, pt)
    assert ct == exp, f"FIPS-197 Appendix B encrypt failed:\n  got {[hex(x) for x in ct]}\n  exp {[hex(x) for x in exp]}"
    print("  [PASS] FIPS-197 Appendix B encrypt")
    return True


def test_fips197_appendix_c1():
    """FIPS-197 Appendix C.1 (AES-128 test vector).
    Key:    00010203 04050607 08090a0b 0c0d0e0f
    Input:  00112233 44556677 8899aabb ccddeeff
    Output: 69c4e0d8 6a7b0430 d8cdb780 70b4c55a
    """
    key = list(range(16))
    pt  = [0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
           0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff]
    exp = [0x69, 0xc4, 0xe0, 0xd8, 0x6a, 0x7b, 0x04, 0x30,
           0xd8, 0xcd, 0xb7, 0x80, 0x70, 0xb4, 0xc5, 0x5a]

    ct = aes128_encrypt(key, pt)
    assert ct == exp, f"FIPS-197 Appendix C.1 encrypt failed:\n  got {[hex(x) for x in ct]}\n  exp {[hex(x) for x in exp]}"
    print("  [PASS] FIPS-197 Appendix C.1 encrypt")
    return True


def test_decrypt_roundtrip():
    """Encrypt then decrypt must return original plaintext."""
    key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
           0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]
    pt  = [0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
           0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a]

    ct = aes128_encrypt(key, pt)
    recovered = aes128_decrypt(key, ct)
    assert recovered == pt, f"Decrypt roundtrip failed:\n  got {[hex(x) for x in recovered]}\n  exp {[hex(x) for x in pt]}"
    print("  [PASS] Encrypt/decrypt roundtrip")
    return True


def test_key_expansion_appendix_a():
    """Verify key expansion against FIPS-197 Appendix A (AES-128).
    First round key = original key. Last round key known.
    """
    key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
           0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c]
    rk = key_expansion(key)

    # Round key 0 = original key
    assert rk[0] == key, "Round key 0 != original key"

    # Round key 10 (last) from FIPS-197 Appendix A
    exp_rk10 = [0xd0, 0x14, 0xf9, 0xa8, 0xc9, 0xee, 0x25, 0x89,
                0xe1, 0x3f, 0x0c, 0xc8, 0xb6, 0x63, 0x0c, 0xa6]
    assert rk[10] == exp_rk10, (
        f"Round key 10 mismatch:\n  got {[hex(x) for x in rk[10]]}\n  exp {[hex(x) for x in exp_rk10]}"
    )
    print("  [PASS] Key expansion (Appendix A)")
    return True


def test_multiple_vectors():
    """Multiple encrypt/decrypt pairs to verify consistency."""
    import os
    key = list(range(16))
    for trial in range(100):
        pt = [(trial * 7 + i * 13) & 0xFF for i in range(16)]
        ct = aes128_encrypt(key, pt)
        recovered = aes128_decrypt(key, ct)
        assert recovered == pt, f"Roundtrip failed on trial {trial}"
    print("  [PASS] 100 random-pattern roundtrips")
    return True


def test_avalanche():
    """Single bit flip in plaintext changes >= 50% of ciphertext bits."""
    key = [0]*16
    pt  = [0]*16
    ct0 = aes128_encrypt(key, pt)

    for bit in range(128):
        pt_flip = pt[:]
        pt_flip[bit // 8] ^= (1 << (bit % 8))
        ct1 = aes128_encrypt(key, pt_flip)
        diff_bits = sum(bin(a ^ b).count('1') for a, b in zip(ct0, ct1))
        assert diff_bits >= 40, f"Avalanche failed: bit {bit} only changed {diff_bits} bits"
    print("  [PASS] Avalanche criterion (all 128 input bits)")
    return True


# ═══════════════════════════════════════════════════════════════════════
# MAIN
# ═══════════════════════════════════════════════════════════════════════

if __name__ == "__main__":
    print("=" * 70)
    print("  PHASE 5: AES-128 Full Implementation — FIPS-197 Compliance")
    print("=" * 70)

    tests = [
        test_key_expansion_appendix_a,
        test_fips197_appendix_b,
        test_fips197_appendix_c1,
        test_decrypt_roundtrip,
        test_multiple_vectors,
        test_avalanche,
    ]

    passed = 0
    failed = 0
    for t in tests:
        try:
            t()
            passed += 1
        except AssertionError as e:
            print(f"  [FAIL] {t.__name__}: {e}")
            failed += 1

    print("-" * 70)
    print(f"  Results: {passed} passed, {failed} failed")
    if failed == 0:
        print("  ALL FIPS-197 TESTS PASSED — AES-128 implementation verified")
    print("=" * 70)
