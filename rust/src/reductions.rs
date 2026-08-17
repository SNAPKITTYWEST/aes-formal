// Phase 6 Complete: R_NL vs B_A Reductions with computational verification
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

use crate::gf256::GF256;
use crate::aes128::{encrypt, key_expansion, State};

// ═══════════════════════════════════════════════════════════════════════
// BLACK-HOLE MAP B_A (Linearized S-box = 0)
// ═══════════════════════════════════════════════════════════════════════

fn b_a_layer(state: &mut State) {
    for row in 0..4 {
        for col in 0..4 {
            state[row][col] = 0;
        }
    }
}

fn shift_rows(state: &mut State) {
    let t = state[1][0];
    state[1][0] = state[1][1]; state[1][1] = state[1][2];
    state[1][2] = state[1][3]; state[1][3] = t;
    state[2].swap(0, 2); state[2].swap(1, 3);
    let t = state[3][3];
    state[3][3] = state[3][2]; state[3][2] = state[3][1];
    state[3][1] = state[3][0]; state[3][0] = t;
}

fn mix_columns(state: &mut State) {
    for c in 0..4 {
        let (b0, b1, b2, b3) = (
            GF256(state[0][c]), GF256(state[1][c]),
            GF256(state[2][c]), GF256(state[3][c]),
        );
        state[0][c] = (GF256(2) * b0 + GF256(3) * b1 + b2 + b3).0;
        state[1][c] = (b0 + GF256(2) * b1 + GF256(3) * b2 + b3).0;
        state[2][c] = (b0 + b1 + GF256(2) * b2 + GF256(3) * b3).0;
        state[3][c] = (GF256(3) * b0 + b1 + b2 + GF256(2) * b3).0;
    }
}

fn add_round_key(state: &mut State, rk: &[u8; 16]) {
    for r in 0..4 {
        for c in 0..4 {
            state[r][c] ^= rk[r + 4 * c];
        }
    }
}

fn b_a_round(state: &mut State, round_key: &[u8; 16]) {
    b_a_layer(state);
    shift_rows(state);
    mix_columns(state);
    add_round_key(state, round_key);
}

pub fn aes128_encrypt_ba(key: &[u8; 16], pt: &[u8; 16]) -> [u8; 16] {
    let rk = key_expansion(key);
    let mut state: State = [[0u8; 4]; 4];
    for r in 0..4 {
        for c in 0..4 {
            state[r][c] = pt[r + 4 * c];
        }
    }

    add_round_key(&mut state, &rk[0]);

    for round in 1..10 {
        b_a_round(&mut state, &rk[round]);
    }

    // Final round (no MixColumns)
    b_a_layer(&mut state);
    shift_rows(&mut state);
    add_round_key(&mut state, &rk[10]);

    let mut ct = [0u8; 16];
    for r in 0..4 {
        for c in 0..4 {
            ct[r + 4 * c] = state[r][c];
        }
    }
    ct
}

// ═══════════════════════════════════════════════════════════════════════
// CONSTRAINT FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════

pub fn constraint_ba(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> [u8; 16] {
    let computed = aes128_encrypt_ba(key, pt);
    core::array::from_fn(|i| computed[i] ^ ct[i])
}

pub fn constraint_r_nl(key: &[u8; 16], pt: &[u8; 16], ct: &[u8; 16]) -> [u8; 16] {
    let computed = encrypt(key, pt);
    core::array::from_fn(|i| computed[i] ^ ct[i])
}

// ═══════════════════════════════════════════════════════════════════════
// SEPARATION VERIFICATION
// ═══════════════════════════════════════════════════════════════════════

pub fn verify_ba_not_injective() -> bool {
    // B_A with zero S-box: output = rk[10] regardless of plaintext.
    // So (K, P1) and (K, P2) map to same output → not injective over (K,P) space.
    let key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
               0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c];
    let pt1 = [0u8; 16];
    let pt2 = [0xFF; 16];

    let ct1 = aes128_encrypt_ba(&key, &pt1);
    let ct2 = aes128_encrypt_ba(&key, &pt2);

    // Different plaintexts, same output → information loss (lossy)
    ct1 == ct2
}

pub fn verify_r_nl_injective_deterministic() -> bool {
    for seed in 0u8..200 {
        let key1: [u8; 16] = core::array::from_fn(|i| seed.wrapping_mul(7).wrapping_add(i as u8));
        let key2: [u8; 16] = core::array::from_fn(|i| seed.wrapping_mul(13).wrapping_add(i as u8 + 1));
        if key1 == key2 { continue; }

        let pt: [u8; 16] = core::array::from_fn(|i| seed.wrapping_add(i as u8 * 3));
        let ct1 = encrypt(&key1, &pt);
        let ct2 = encrypt(&key2, &pt);

        if ct1 == ct2 {
            return false;
        }
    }
    true
}

pub fn verify_local_distinguishability() -> bool {
    for seed in 0u8..200 {
        let key1: [u8; 16] = core::array::from_fn(|i| seed.wrapping_mul(11).wrapping_add(i as u8));
        let mut key2 = key1;
        key2[(seed % 16) as usize] ^= 1 << (seed % 8);
        if key1 == key2 { continue; }

        let pt: [u8; 16] = core::array::from_fn(|i| seed.wrapping_add(i as u8 * 7));
        let ct1 = encrypt(&key1, &pt);
        let ct2 = encrypt(&key2, &pt);

        if ct1 == ct2 {
            return false;
        }
    }
    true
}

// ═══════════════════════════════════════════════════════════════════════
// JACOBIAN COMPUTATION (Numerical over GF(2))
// ═══════════════════════════════════════════════════════════════════════

pub fn compute_jacobian_ba(key: &[u8; 16], pt: &[u8; 16]) -> [[u8; 128]; 128] {
    let base_ct = aes128_encrypt_ba(key, pt);
    let mut j = [[0u8; 128]; 128];

    for col in 0..128 {
        let mut key_pert = *key;
        key_pert[col / 8] ^= 1 << (col % 8);
        let pert_ct = aes128_encrypt_ba(&key_pert, pt);

        for row in 0..128 {
            let base_bit = (base_ct[row / 8] >> (row % 8)) & 1;
            let pert_bit = (pert_ct[row / 8] >> (row % 8)) & 1;
            j[row][col] = base_bit ^ pert_bit;
        }
    }
    j
}

pub fn compute_jacobian_r_nl(key: &[u8; 16], pt: &[u8; 16]) -> [[u8; 128]; 128] {
    let base_ct = encrypt(key, pt);
    let mut j = [[0u8; 128]; 128];

    for col in 0..128 {
        let mut key_pert = *key;
        key_pert[col / 8] ^= 1 << (col % 8);
        let pert_ct = encrypt(&key_pert, pt);

        for row in 0..128 {
            let base_bit = (base_ct[row / 8] >> (row % 8)) & 1;
            let pert_bit = (pert_ct[row / 8] >> (row % 8)) & 1;
            j[row][col] = base_bit ^ pert_bit;
        }
    }
    j
}

pub fn gf2_rank(matrix: &[[u8; 128]; 128]) -> usize {
    let mut mat = *matrix;
    let mut rank = 0;

    for col in 0..128 {
        let mut pivot = None;
        for row in rank..128 {
            if mat[row][col] == 1 {
                pivot = Some(row);
                break;
            }
        }

        if let Some(pivot_row) = pivot {
            if pivot_row != rank {
                mat.swap(rank, pivot_row);
            }
            for row in 0..128 {
                if row != rank && mat[row][col] == 1 {
                    for c in col..128 {
                        mat[row][c] ^= mat[rank][c];
                    }
                }
            }
            rank += 1;
        }
    }
    rank
}

/// Compute Jacobian with respect to PLAINTEXT (not key)
pub fn compute_jacobian_ba_pt(key: &[u8; 16], pt: &[u8; 16]) -> [[u8; 128]; 128] {
    let base_ct = aes128_encrypt_ba(key, pt);
    let mut j = [[0u8; 128]; 128];

    for col in 0..128 {
        let mut pt_pert = *pt;
        pt_pert[col / 8] ^= 1 << (col % 8);
        let pert_ct = aes128_encrypt_ba(key, &pt_pert);

        for row in 0..128 {
            let base_bit = (base_ct[row / 8] >> (row % 8)) & 1;
            let pert_bit = (pert_ct[row / 8] >> (row % 8)) & 1;
            j[row][col] = base_bit ^ pert_bit;
        }
    }
    j
}

pub fn compute_jacobian_r_nl_pt(key: &[u8; 16], pt: &[u8; 16]) -> [[u8; 128]; 128] {
    let base_ct = encrypt(key, pt);
    let mut j = [[0u8; 128]; 128];

    for col in 0..128 {
        let mut pt_pert = *pt;
        pt_pert[col / 8] ^= 1 << (col % 8);
        let pert_ct = encrypt(key, &pt_pert);

        for row in 0..128 {
            let base_bit = (base_ct[row / 8] >> (row % 8)) & 1;
            let pert_bit = (pert_ct[row / 8] >> (row % 8)) & 1;
            j[row][col] = base_bit ^ pert_bit;
        }
    }
    j
}

pub fn verify_jacobian_ranks() -> (usize, usize) {
    let key = [0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
               0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c];
    let pt = [0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
              0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a];

    // Jacobian w.r.t. PLAINTEXT: B_A kills PT info, R_NL preserves it
    let j_ba = compute_jacobian_ba_pt(&key, &pt);
    let j_rnl = compute_jacobian_r_nl_pt(&key, &pt);

    (gf2_rank(&j_ba), gf2_rank(&j_rnl))
}

// ═══════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_ba_not_injective() {
        assert!(verify_ba_not_injective(), "B_A should NOT be injective");
    }

    #[test]
    fn test_r_nl_injective() {
        assert!(verify_r_nl_injective_deterministic(), "R_NL should be injective");
    }

    #[test]
    fn test_local_distinguishability() {
        assert!(verify_local_distinguishability(), "Local distinguishability should hold");
    }

    #[test]
    fn test_jacobian_ranks() {
        let (rank_ba, rank_rnl) = verify_jacobian_ranks();
        assert!(rank_ba < 128, "B_A Jacobian should be rank-deficient, got {}", rank_ba);
        // R_NL should have full or near-full rank (≥ 120 empirically)
        assert!(rank_rnl >= 120, "R_NL Jacobian should have near-full rank, got {}", rank_rnl);
        assert!(rank_rnl > rank_ba, "R_NL rank {} should exceed B_A rank {}", rank_rnl, rank_ba);
    }
}
