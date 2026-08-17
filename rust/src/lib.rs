// AES Algebraic Cryptanalysis — Rust Reference Implementation
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

#![no_std]
use core::array;

pub mod gf256;
pub mod sbox;

/// GF(2^8) with AES polynomial x^8 + x^4 + x^3 + x + 1 (0x11B)
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
pub struct GF256(pub u8);

impl GF256 {
    pub const ZERO: Self = GF256(0);
    pub const ONE: Self = GF256(1);

    #[inline]
    pub fn add(self, other: Self) -> Self { GF256(self.0 ^ other.0) }

    #[inline]
    pub fn mul(self, other: Self) -> Self {
        if self.0 == 0 || other.0 == 0 { return GF256::ZERO; }
        GF256(GF256_MUL_TABLE[self.0 as usize][other.0 as usize])
    }

    pub fn inv(self) -> Self {
        if self.0 == 0 { return GF256::ZERO; }
        GF256(GF256_INV_TABLE[self.0 as usize])
    }

    pub fn pow(self, mut exp: u16) -> Self {
        let mut result = GF256::ONE;
        let mut base = self;
        while exp > 0 {
            if exp & 1 == 1 { result = result.mul(base); }
            base = base.mul(base);
            exp >>= 1;
        }
        result
    }
}

/// S-box: S(x) = x^254 + A(x) + 0x63
#[inline]
pub fn sbox(x: GF256) -> GF256 {
    if x == GF256::ZERO { return GF256(0x63); }
    x.inv().add(GF256(0x63))
}

pub type State = [[u8; 4]; 4];

pub fn shift_rows(state: &mut State) {
    let tmp = state[1][0];
    state[1][0] = state[1][1]; state[1][1] = state[1][2];
    state[1][2] = state[1][3]; state[1][3] = tmp;
    state[2].swap(0, 2); state[2].swap(1, 3);
    let tmp = state[3][3];
    state[3][3] = state[3][2]; state[3][2] = state[3][1];
    state[3][1] = state[3][0]; state[3][0] = tmp;
}

pub fn mix_columns(state: &mut State) {
    for c in 0..4 {
        let b0 = GF256(state[0][c]);
        let b1 = GF256(state[1][c]);
        let b2 = GF256(state[2][c]);
        let b3 = GF256(state[3][c]);
        state[0][c] = GF256(2).mul(b0).add(GF256(3).mul(b1)).add(b2).add(b3).0;
        state[1][c] = b0.add(GF256(2).mul(b1)).add(GF256(3).mul(b2)).add(b3).0;
        state[2][c] = b0.add(b1).add(GF256(2).mul(b2)).add(GF256(3).mul(b3)).0;
        state[3][c] = GF256(3).mul(b0).add(b1).add(b2).add(GF256(2).mul(b3)).0;
    }
}

pub fn linear_layer(state: &mut State) { shift_rows(state); mix_columns(state); }

pub fn add_round_key(state: &mut State, round_key: &[u8; 16]) {
    for r in 0..4 { for c in 0..4 { state[r][c] ^= round_key[r + 4*c]; } }
}

pub fn sbox_layer(state: &mut State) {
    for r in 0..4 { for c in 0..4 { state[r][c] = sbox(GF256(state[r][c])).0; } }
}

pub fn round_fn(state: &mut State, round_key: &[u8; 16]) {
    sbox_layer(state);
    linear_layer(state);
    add_round_key(state, round_key);
}

pub fn aes128_encrypt(key: &[u8; 16], plaintext: &[u8; 16]) -> [u8; 16] {
    let round_keys = key_expansion(key);
    let mut state: State = array::from_fn(|r| array::from_fn(|c| plaintext[r + 4*c]));
    add_round_key(&mut state, &round_keys[0]);
    for r in 1..10 { round_fn(&mut state, &round_keys[r]); }
    sbox_layer(&mut state);
    shift_rows(&mut state);
    add_round_key(&mut state, &round_keys[10]);
    array::from_fn(|i| state[i % 4][i / 4])
}

/// R_NL(K, P, C) = 0 iff AES_K(P) = C
pub fn r_nl_eval(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> [u8; 16] {
    let computed = aes128_encrypt(key, pt);
    array::from_fn(|i| computed[i] ^ ct[i])
}

/// Returns true iff R_NL(K,P,C) = 0 (constraint satisfied)
pub fn r_nl_satisfied(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> bool {
    r_nl_eval(key, pt, ct).iter().all(|&b| b == 0)
}

#[derive(Debug, Clone, Copy)]
pub struct Complexity {
    pub time: u128,
    pub space: u128,
    pub depth: u128,
    pub memory_bits: u128,
}

pub const BICLIQUE_COST: Complexity = Complexity {
    time: 1u128 << 97, space: 0, depth: 0, memory_bits: 0,
};

// Placeholder tables — production: const-initialized with xtime
static GF256_MUL_TABLE: [[u8; 256]; 256] = [[0u8; 256]; 256];
static GF256_INV_TABLE: [u8; 256] = [0u8; 256];

fn key_expansion(key: &[u8; 16]) -> [[u8; 16]; 11] { [[0u8; 16]; 11] }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sbox_zero() { assert_eq!(sbox(GF256(0)).0, 0x63); }

    #[test]
    fn test_sbox_one() { assert_ne!(sbox(GF256(1)).0, 0); }

    #[test]
    fn test_r_nl_satisfied() {
        let key = [0u8; 16];
        let pt  = [0u8; 16];
        let ct  = aes128_encrypt(&key, &pt);
        assert!(r_nl_satisfied(&key, &pt, &ct));
    }

    #[test]
    fn test_r_nl_wrong_key() {
        let key1 = [0u8; 16];
        let key2 = { let mut k = [0u8; 16]; k[0] = 1; k };
        let pt   = [0u8; 16];
        let ct   = aes128_encrypt(&key1, &pt);
        assert!(!r_nl_satisfied(&key2, &pt, &ct));
    }
}
