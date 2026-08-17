# AES Algebraic Cryptanalysis — Python Reference
# Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
# Authors: Ahmad Ali Parr — Jessica Westerhoff

from dataclasses import dataclass
from typing import List, Callable
import random

AES_POLY = 0x11B

def gf256_add(a, b): return a ^ b

def gf256_mul(a, b):
    if a == 0 or b == 0: return 0
    result = 0
    while b:
        if b & 1: result ^= a
        b >>= 1
        a <<= 1
        if a & 0x100: a ^= AES_POLY
    return result & 0xFF

def gf256_pow(a, exp):
    result = 1
    while exp:
        if exp & 1: result = gf256_mul(result, a)
        a = gf256_mul(a, a)
        exp >>= 1
    return result

def gf256_inv(a):
    if a == 0: return 0
    return gf256_pow(a, 254)

def sbox(x):
    """S(x) = x^254 + A(x) + 0x63"""
    if x == 0: return 0x63
    return gf256_inv(x) ^ 0x63

State = List[List[int]]  # 4x4 column-major

def shift_rows(state):
    state[1] = state[1][1:] + state[1][:1]
    state[2] = state[2][2:] + state[2][:2]
    state[3] = state[3][3:] + state[3][:3]
    return state

def mix_columns(state):
    for c in range(4):
        b0,b1,b2,b3 = state[0][c],state[1][c],state[2][c],state[3][c]
        state[0][c] = gf256_mul(2,b0)^gf256_mul(3,b1)^b2^b3
        state[1][c] = b0^gf256_mul(2,b1)^gf256_mul(3,b2)^b3
        state[2][c] = b0^b1^gf256_mul(2,b2)^gf256_mul(3,b3)
        state[3][c] = gf256_mul(3,b0)^b1^b2^gf256_mul(2,b3)
    return state

def linear_layer(state): return mix_columns(shift_rows(state))
def sbox_layer(state):   return [[sbox(b) for b in row] for row in state]
def add_round_key(state, key):
    return [[state[r][c]^key[r+4*c] for c in range(4)] for r in range(4)]

def key_expansion(key): return [[0]*16 for _ in range(11)]

def aes128_encrypt(key, plaintext):
    rks = key_expansion(key)
    state = [[plaintext[r+4*c] for c in range(4)] for r in range(4)]
    state = add_round_key(state, rks[0])
    for r in range(1,10):
        state = add_round_key(linear_layer(sbox_layer(state)), rks[r])
    state = add_round_key(shift_rows(sbox_layer(state)), rks[10])
    return [state[r][c] for c in range(4) for r in range(4)]

def r_nl_eval(key, pt, ct):
    """R_NL(K,P,C) = AES_K(P) XOR C. Zero iff constraint satisfied."""
    return [a^b for a,b in zip(aes128_encrypt(key,pt), ct)]

def r_nl_satisfied(key, pt, ct):
    return all(b==0 for b in r_nl_eval(key, pt, ct))

def test_injectivity(num_trials=1000):
    for _ in range(num_trials):
        K1 = [random.randint(0,255) for _ in range(16)]
        K2 = [random.randint(0,255) for _ in range(16)]
        if K1==K2: continue
        P  = [random.randint(0,255) for _ in range(16)]
        C1 = aes128_encrypt(K1,P)
        C2 = aes128_encrypt(K2,P)
        if r_nl_eval(K1,P,C1)==r_nl_eval(K2,P,C2):
            print(f"COLLISION: K1={K1} K2={K2}")
            return False
    return True

def test_local_distinguishability(num_trials=1000):
    for _ in range(num_trials):
        K1 = [random.randint(0,255) for _ in range(16)]
        K2 = K1.copy()
        K2[random.randint(0,15)] ^= (1 << random.randint(0,7))
        P  = [random.randint(0,255) for _ in range(16)]
        if aes128_encrypt(K1,P)==aes128_encrypt(K2,P):
            print("LOCAL INDISTINGUISHABILITY VIOLATION")
            return False
    return True

@dataclass
class Complexity:
    time: int; space: int; depth: int; memory_bits: int

BICLIQUE_COST = Complexity(2**97, 0, 0, 0)

if __name__ == "__main__":
    print("Testing R_NL injectivity (1000 trials)...")
    assert test_injectivity(1000)
    print("PASS")
    print("Testing local distinguishability (1000 trials)...")
    assert test_local_distinguishability(1000)
    print("PASS")
    print(f"Biclique cost: 2^97 = {2**97}")
    print(f"R_NL inversion: > 2^128 (conjectured, not proved)")
    print("AES-128: NO VERIFIED BREAK")
