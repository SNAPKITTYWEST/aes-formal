# Phase 2: GF(2^8) with property-based testing
# Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
# Authors: Ahmad Ali Parr — Jessica Westerhoff

AES_POLY = 0x11B

LOG_TABLE     = [0] * 256
ANTILOG_TABLE = [0] * 256
INV_TABLE     = [0] * 256
FROBENIUS_TABLE = [0] * 256

def gf_mul_raw(a, b):
    result = 0
    while b:
        if b & 1: result ^= a
        b >>= 1; a <<= 1
        if a & 0x100: a ^= 0x1B
    return result & 0xFF

def _init():
    x = 1
    for i in range(255):
        LOG_TABLE[x] = i; ANTILOG_TABLE[i] = x
        x = gf_mul_raw(x, 3)
    ANTILOG_TABLE[255] = 1
    INV_TABLE[0] = 0; INV_TABLE[1] = 1
    for i in range(2, 256):
        for j in range(1, 256):
            if gf_mul_raw(i, j) == 1: INV_TABLE[i] = j; break
    for i in range(256): FROBENIUS_TABLE[i] = gf_mul_raw(i, i)

_init()

class GF256:
    __slots__ = ('val',)
    def __init__(self, val): self.val = val & 0xFF
    def __add__(self, o):    return GF256(self.val ^ o.val)
    def __mul__(self, o):
        if not self.val or not o.val: return GF256(0)
        return GF256(ANTILOG_TABLE[(LOG_TABLE[self.val] + LOG_TABLE[o.val]) % 255])
    def inv(self):    return GF256(INV_TABLE[self.val])
    def frobenius(self): return GF256(FROBENIUS_TABLE[self.val])
    def pow(self, e):
        if not self.val: return GF256(1 if e == 0 else 0)
        return GF256(ANTILOG_TABLE[(LOG_TABLE[self.val] * e) % 255])
    def __eq__(self, o): return isinstance(o, GF256) and self.val == o.val
    def __repr__(self): return f"GF256(0x{self.val:02X})"

ZERO = GF256(0); ONE = GF256(1)

def sbox(x):
    return GF256(0x63) if x == ZERO else x.inv() + GF256(0x63)

def inv_sbox(x):
    y = x + GF256(0x63)
    return ZERO if y == ZERO else y.inv()

def verify_field_axioms():
    for a in range(256):
        x = GF256(a)
        assert (x + ZERO).val == a
        assert (x + x).val == 0
    for a in range(1, 256):
        x = GF256(a)
        assert (x * ONE).val == a
        assert (x * x.inv()).val == 1
    # Distributivity sample
    import random
    for _ in range(1000):
        a,b,c = (GF256(random.randint(0,255)) for _ in range(3))
        assert (a * (b + c)).val == ((a*b) + (a*c)).val
    return True

def test_frobenius_additive():
    import random
    for _ in range(1000):
        a = GF256(random.randint(0,255))
        b = GF256(random.randint(0,255))
        assert (a+b).frobenius().val == (a.frobenius() + b.frobenius()).val

def test_sbox_roundtrip():
    for i in range(256):
        assert inv_sbox(sbox(GF256(i))).val == i

if __name__ == "__main__":
    print("Verifying GF(2^8) field axioms...")
    assert verify_field_axioms()
    print("PASS")
    print("Testing Frobenius additivity...")
    test_frobenius_additive()
    print("PASS")
    print("Testing S-box roundtrip...")
    test_sbox_roundtrip()
    print("PASS")
    print("S-box(0x00) =", sbox(GF256(0x00)))
    print("S-box(0x53) =", sbox(GF256(0x53)))
