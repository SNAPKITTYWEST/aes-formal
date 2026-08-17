// Phase 5-6: Complete AES-128 with formal verification hooks
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff

use crate::gf256::GF256;
use crate::sbox::{sbox_full as sbox, inv_sbox_full as inv_sbox};

pub type State     = [[u8; 4]; 4];
pub type RoundKeys = [[u8; 16]; 11];

const RCON: [u8; 11] = [0x00, 0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80, 0x1B, 0x36];

pub fn key_expansion(key: &[u8; 16]) -> RoundKeys {
    let mut rk = [[0u8; 16]; 11];
    rk[0] = *key;
    for r in 1..11 {
        let prev = rk[r - 1];
        let mut curr = [0u8; 16];
        let t = [
            sbox(GF256(prev[13])).0 ^ RCON[r],
            sbox(GF256(prev[14])).0,
            sbox(GF256(prev[15])).0,
            sbox(GF256(prev[12])).0,
        ];
        for i in 0..4  { curr[i] = prev[i] ^ t[i]; }
        for i in 4..16 { curr[i] = prev[i] ^ curr[i - 4]; }
        rk[r] = curr;
    }
    rk
}

#[inline]
pub fn sub_bytes(s: &mut State) {
    for r in 0..4 { for c in 0..4 { s[r][c] = sbox(GF256(s[r][c])).0; } }
}

#[inline]
pub fn shift_rows(s: &mut State) {
    let t = s[1][0]; s[1][0]=s[1][1]; s[1][1]=s[1][2]; s[1][2]=s[1][3]; s[1][3]=t;
    s[2].swap(0,2); s[2].swap(1,3);
    let t = s[3][3]; s[3][3]=s[3][2]; s[3][2]=s[3][1]; s[3][1]=s[3][0]; s[3][0]=t;
}

#[inline]
pub fn mix_columns(s: &mut State) {
    for c in 0..4 {
        let (b0,b1,b2,b3) = (GF256(s[0][c]),GF256(s[1][c]),GF256(s[2][c]),GF256(s[3][c]));
        s[0][c] = (GF256(2)*b0 + GF256(3)*b1 + b2 + b3).0;
        s[1][c] = (b0 + GF256(2)*b1 + GF256(3)*b2 + b3).0;
        s[2][c] = (b0 + b1 + GF256(2)*b2 + GF256(3)*b3).0;
        s[3][c] = (GF256(3)*b0 + b1 + b2 + GF256(2)*b3).0;
    }
}

#[inline]
pub fn add_round_key(s: &mut State, rk: &[u8; 16]) {
    for r in 0..4 { for c in 0..4 { s[r][c] ^= rk[r + 4*c]; } }
}

fn load_state(pt: &[u8; 16]) -> State {
    let mut s = [[0u8;4];4];
    for r in 0..4 { for c in 0..4 { s[r][c] = pt[r+4*c]; } }
    s
}
fn dump_state(s: &State) -> [u8;16] {
    let mut out = [0u8;16];
    for r in 0..4 { for c in 0..4 { out[r+4*c] = s[r][c]; } }
    out
}

pub fn encrypt(key: &[u8; 16], pt: &[u8; 16]) -> [u8; 16] {
    let rk = key_expansion(key);
    let mut s = load_state(pt);
    add_round_key(&mut s, &rk[0]);
    for r in 1..10 { sub_bytes(&mut s); shift_rows(&mut s); mix_columns(&mut s); add_round_key(&mut s, &rk[r]); }
    sub_bytes(&mut s); shift_rows(&mut s); add_round_key(&mut s, &rk[10]);
    dump_state(&s)
}

pub fn decrypt(key: &[u8; 16], ct: &[u8; 16]) -> [u8; 16] {
    let rk = key_expansion(key);
    let mut s = load_state(ct);
    add_round_key(&mut s, &rk[10]);
    for r in (1..10).rev() {
        inv_shift_rows(&mut s); inv_sub_bytes(&mut s);
        add_round_key(&mut s, &rk[r]); inv_mix_columns(&mut s);
    }
    inv_shift_rows(&mut s); inv_sub_bytes(&mut s); add_round_key(&mut s, &rk[0]);
    dump_state(&s)
}

fn inv_sub_bytes(s: &mut State) {
    for r in 0..4 { for c in 0..4 { s[r][c] = inv_sbox(GF256(s[r][c])).0; } }
}
fn inv_shift_rows(s: &mut State) {
    let t = s[1][3]; s[1][3]=s[1][2]; s[1][2]=s[1][1]; s[1][1]=s[1][0]; s[1][0]=t;
    s[2].swap(0,2); s[2].swap(1,3);
    let t = s[3][0]; s[3][0]=s[3][1]; s[3][1]=s[3][2]; s[3][2]=s[3][3]; s[3][3]=t;
}
fn inv_mix_columns(s: &mut State) {
    for c in 0..4 {
        let (b0,b1,b2,b3) = (GF256(s[0][c]),GF256(s[1][c]),GF256(s[2][c]),GF256(s[3][c]));
        s[0][c] = (GF256(0x0E)*b0 + GF256(0x0B)*b1 + GF256(0x0D)*b2 + GF256(0x09)*b3).0;
        s[1][c] = (GF256(0x09)*b0 + GF256(0x0E)*b1 + GF256(0x0B)*b2 + GF256(0x0D)*b3).0;
        s[2][c] = (GF256(0x0D)*b0 + GF256(0x09)*b1 + GF256(0x0E)*b2 + GF256(0x0B)*b3).0;
        s[3][c] = (GF256(0x0B)*b0 + GF256(0x0D)*b1 + GF256(0x09)*b2 + GF256(0x0E)*b3).0;
    }
}

/// R_NL(K,P,C) = AES_K(P) XOR C. Zero iff satisfied.
pub fn r_nl_eval(key: &[u8;16], pt: &[u8;16], ct: &[u8;16]) -> [u8;16] {
    let computed = encrypt(key, pt);
    core::array::from_fn(|i| computed[i] ^ ct[i])
}

pub fn r_nl_satisfied(key: &[u8;16], pt: &[u8;16], ct: &[u8;16]) -> bool {
    r_nl_eval(key, pt, ct).iter().all(|&b| b == 0)
}

pub fn verify_fips197() -> bool {
    let key = [0x2b,0x7e,0x15,0x16,0x28,0xae,0xd2,0xa6,0xab,0xf7,0x15,0x88,0x09,0xcf,0x4f,0x3c];
    let pt  = [0x6b,0xc1,0xbe,0xe2,0x2e,0x40,0x9f,0x96,0xe9,0x3d,0x7e,0x11,0x73,0x93,0x17,0x2a];
    let exp = [0x3a,0xd7,0x7b,0xb4,0x0d,0x7a,0x36,0x60,0xa8,0x9e,0xca,0xf3,0x24,0x66,0xef,0x97];
    encrypt(&key, &pt) == exp
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test] fn test_fips197() { assert!(verify_fips197()); }
    #[test] fn test_encrypt_decrypt() {
        let key = [0u8;16]; let pt = [0x42u8;16];
        assert_eq!(decrypt(&key, &encrypt(&key, &pt)), pt);
    }
    #[test] fn test_r_nl_satisfied() {
        let key = [0u8;16]; let pt = [0u8;16];
        let ct = encrypt(&key, &pt);
        assert!(r_nl_satisfied(&key, &pt, &ct));
    }
    #[test] fn test_r_nl_wrong_key() {
        let k1 = [0u8;16]; let mut k2 = [0u8;16]; k2[0]=1;
        let pt = [0u8;16]; let ct = encrypt(&k1, &pt);
        assert!(!r_nl_satisfied(&k2, &pt, &ct));
    }
}
