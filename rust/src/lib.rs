// AES Algebraic Cryptanalysis — Rust Reference Implementation
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

#![no_std]

pub mod gf256;
pub mod sbox;
pub mod linear_layer;
pub mod aes128;

pub use gf256::GF256;
pub use sbox::{sbox_full as sbox_fips, inv_sbox_full as inv_sbox_fips};
pub use aes128::{encrypt as aes128_encrypt, decrypt as aes128_decrypt};

pub type State = [[u8; 4]; 4];

/// R_NL(K, P, C) = 0 iff AES_K(P) = C
pub fn r_nl_eval(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> [u8; 16] {
    aes128::r_nl_eval(key, pt, ct)
}

/// Returns true iff R_NL(K,P,C) = 0 (constraint satisfied)
pub fn r_nl_satisfied(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> bool {
    aes128::r_nl_satisfied(key, pt, ct)
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

#[cfg(test)]
mod tests {
    use super::*;

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

    #[test]
    fn test_fips197_via_aes128() {
        assert!(aes128::verify_fips197());
    }
}
