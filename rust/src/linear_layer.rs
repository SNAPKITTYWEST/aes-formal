// Phase 4 Complete: Linear Layer with MDS Verification
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

use crate::gf256::GF256;
use crate::sbox::{sbox_full, inv_sbox_full};

pub type State = [[u8; 4]; 4];

// ═══════════════════════════════════════════════════════════════════════
// SHIFTROWS
// ═══════════════════════════════════════════════════════════════════════

pub fn shift_rows(state: &mut State) {
    let tmp = state[1][0];
    state[1][0] = state[1][1];
    state[1][1] = state[1][2];
    state[1][2] = state[1][3];
    state[1][3] = tmp;

    state[2].swap(0, 2);
    state[2].swap(1, 3);

    let tmp = state[3][3];
    state[3][3] = state[3][2];
    state[3][2] = state[3][1];
    state[3][1] = state[3][0];
    state[3][0] = tmp;
}

pub fn inv_shift_rows(state: &mut State) {
    let tmp = state[1][3];
    state[1][3] = state[1][2];
    state[1][2] = state[1][1];
    state[1][1] = state[1][0];
    state[1][0] = tmp;

    state[2].swap(0, 2);
    state[2].swap(1, 3);

    let tmp = state[3][0];
    state[3][0] = state[3][1];
    state[3][1] = state[3][2];
    state[3][2] = state[3][3];
    state[3][3] = tmp;
}

// ═══════════════════════════════════════════════════════════════════════
// MIXCOLUMNS (MDS)
// ═══════════════════════════════════════════════════════════════════════

pub fn mix_columns(state: &mut State) {
    for col in 0..4 {
        let b0 = GF256(state[0][col]);
        let b1 = GF256(state[1][col]);
        let b2 = GF256(state[2][col]);
        let b3 = GF256(state[3][col]);

        state[0][col] = (GF256(2).mul(b0)).add(GF256(3).mul(b1)).add(b2).add(b3).0;
        state[1][col] = b0.add(GF256(2).mul(b1)).add(GF256(3).mul(b2)).add(b3).0;
        state[2][col] = b0.add(b1).add(GF256(2).mul(b2)).add(GF256(3).mul(b3)).0;
        state[3][col] = (GF256(3).mul(b0)).add(b1).add(b2).add(GF256(2).mul(b3)).0;
    }
}

pub fn inv_mix_columns(state: &mut State) {
    for col in 0..4 {
        let b0 = GF256(state[0][col]);
        let b1 = GF256(state[1][col]);
        let b2 = GF256(state[2][col]);
        let b3 = GF256(state[3][col]);

        state[0][col] = GF256(0x0E).mul(b0).add(GF256(0x0B).mul(b1)).add(GF256(0x0D).mul(b2)).add(GF256(0x09).mul(b3)).0;
        state[1][col] = GF256(0x09).mul(b0).add(GF256(0x0E).mul(b1)).add(GF256(0x0B).mul(b2)).add(GF256(0x0D).mul(b3)).0;
        state[2][col] = GF256(0x0D).mul(b0).add(GF256(0x09).mul(b1)).add(GF256(0x0E).mul(b2)).add(GF256(0x0B).mul(b3)).0;
        state[3][col] = GF256(0x0B).mul(b0).add(GF256(0x0D).mul(b1)).add(GF256(0x09).mul(b2)).add(GF256(0x0E).mul(b3)).0;
    }
}

// ═══════════════════════════════════════════════════════════════════════
// LINEAR LAYER
// ═══════════════════════════════════════════════════════════════════════

pub fn linear_layer(state: &mut State) {
    shift_rows(state);
    mix_columns(state);
}

pub fn inv_linear_layer(state: &mut State) {
    inv_mix_columns(state);
    inv_shift_rows(state);
}

// ═══════════════════════════════════════════════════════════════════════
// ROUND FUNCTION
// ═══════════════════════════════════════════════════════════════════════

pub fn sbox_layer(state: &mut State) {
    for row in state.iter_mut() {
        for byte in row.iter_mut() {
            *byte = sbox_full(GF256(*byte)).0;
        }
    }
}

pub fn inv_sbox_layer(state: &mut State) {
    for row in state.iter_mut() {
        for byte in row.iter_mut() {
            *byte = inv_sbox_full(GF256(*byte)).0;
        }
    }
}

pub fn add_round_key(state: &mut State, round_key: &[u8; 16]) {
    for row in 0..4 {
        for col in 0..4 {
            state[row][col] ^= round_key[row + 4 * col];
        }
    }
}

pub fn round_fn(state: &mut State, round_key: &[u8; 16]) {
    sbox_layer(state);
    linear_layer(state);
    add_round_key(state, round_key);
}

pub fn inv_round_fn(state: &mut State, round_key: &[u8; 16]) {
    add_round_key(state, round_key);
    inv_linear_layer(state);
    inv_sbox_layer(state);
}

// ═══════════════════════════════════════════════════════════════════════
// MDS VERIFICATION
// ═══════════════════════════════════════════════════════════════════════

fn gf256_det_2x2(m: [[GF256; 2]; 2]) -> GF256 {
    m[0][0].mul(m[1][1]).add(m[0][1].mul(m[1][0]))
}

fn gf256_det_3x3(m: [[GF256; 3]; 3]) -> GF256 {
    let a = m[0][0].mul(m[1][1].mul(m[2][2]).add(m[1][2].mul(m[2][1])));
    let b = m[0][1].mul(m[1][0].mul(m[2][2]).add(m[1][2].mul(m[2][0])));
    let c = m[0][2].mul(m[1][0].mul(m[2][1]).add(m[1][1].mul(m[2][0])));
    a.add(b).add(c)
}

fn gf256_det_4x4(m: [[GF256; 4]; 4]) -> GF256 {
    let mut det = GF256::ZERO;
    for col in 0..4 {
        let mut minor = [[GF256::ZERO; 3]; 3];
        let mut mi = 0;
        for i in 1..4 {
            let mut mj = 0;
            for j in 0..4 {
                if j == col { continue; }
                minor[mi][mj] = m[i][j];
                mj += 1;
            }
            mi += 1;
        }
        det = det.add(m[0][col].mul(gf256_det_3x3(minor)));
    }
    det
}

pub fn verify_mds_all_submatrices() -> bool {
    let mc: [[GF256; 4]; 4] = [
        [GF256(2), GF256(3), GF256(1), GF256(1)],
        [GF256(1), GF256(2), GF256(3), GF256(1)],
        [GF256(1), GF256(1), GF256(2), GF256(3)],
        [GF256(3), GF256(1), GF256(1), GF256(2)],
    ];

    // 1×1: all entries non-zero
    for i in 0..4 {
        for j in 0..4 {
            if mc[i][j] == GF256::ZERO { return false; }
        }
    }

    // 2×2 submatrices (C(4,2)² = 36)
    let pairs: [(usize, usize); 6] = [(0,1),(0,2),(0,3),(1,2),(1,3),(2,3)];
    for &(r0, r1) in pairs.iter() {
        for &(c0, c1) in pairs.iter() {
            let sub = [
                [mc[r0][c0], mc[r0][c1]],
                [mc[r1][c0], mc[r1][c1]],
            ];
            if gf256_det_2x2(sub) == GF256::ZERO { return false; }
        }
    }

    // 3×3 submatrices (C(4,3)² = 16)
    let triples: [(usize, usize, usize); 4] = [(0,1,2),(0,1,3),(0,2,3),(1,2,3)];
    for &(r0, r1, r2) in triples.iter() {
        for &(c0, c1, c2) in triples.iter() {
            let sub = [
                [mc[r0][c0], mc[r0][c1], mc[r0][c2]],
                [mc[r1][c0], mc[r1][c1], mc[r1][c2]],
                [mc[r2][c0], mc[r2][c1], mc[r2][c2]],
            ];
            if gf256_det_3x3(sub) == GF256::ZERO { return false; }
        }
    }

    // 4×4: full matrix
    if gf256_det_4x4(mc) == GF256::ZERO { return false; }

    true
}

pub fn verify_branch_number_5() -> bool {
    // Exhaustive over all single-byte columns (to find minimum)
    // For a truly exhaustive check of all 2^32-1 non-zero inputs,
    // we rely on the MDS proof: MDS ⟹ branch number = n+1 = 5
    let mut min_branch: u8 = 255;

    // Check all weight-1 inputs (4×256 = 1024)
    for pos in 0..4u8 {
        for val in 1..=255u8 {
            let mut col = [0u8; 4];
            col[pos as usize] = val;
            let in_wt = col.iter().filter(|&&b| b != 0).count() as u8;

            let b: [GF256; 4] = [GF256(col[0]), GF256(col[1]), GF256(col[2]), GF256(col[3])];
            let out = [
                GF256(2).mul(b[0]).add(GF256(3).mul(b[1])).add(b[2]).add(b[3]).0,
                b[0].add(GF256(2).mul(b[1])).add(GF256(3).mul(b[2])).add(b[3]).0,
                b[0].add(b[1]).add(GF256(2).mul(b[2])).add(GF256(3).mul(b[3])).0,
                GF256(3).mul(b[0]).add(b[1]).add(b[2]).add(GF256(2).mul(b[3])).0,
            ];
            let out_wt = out.iter().filter(|&&b| b != 0).count() as u8;
            let branch = in_wt + out_wt;
            if branch < min_branch { min_branch = branch; }
        }
    }

    // Weight-1 input with MDS must give weight-4 output → branch = 5
    min_branch == 5
}

// ═══════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shift_rows_correctness() {
        let mut state: State = [
            [0x00, 0x01, 0x02, 0x03],
            [0x10, 0x11, 0x12, 0x13],
            [0x20, 0x21, 0x22, 0x23],
            [0x30, 0x31, 0x32, 0x33],
        ];
        shift_rows(&mut state);
        assert_eq!(state[0], [0x00, 0x01, 0x02, 0x03]); // no shift
        assert_eq!(state[1], [0x11, 0x12, 0x13, 0x10]); // left 1
        assert_eq!(state[2], [0x22, 0x23, 0x20, 0x21]); // left 2
        assert_eq!(state[3], [0x33, 0x30, 0x31, 0x32]); // left 3
    }

    #[test]
    fn test_shift_rows_roundtrip() {
        let original: State = [
            [0xAB, 0xCD, 0xEF, 0x01],
            [0x23, 0x45, 0x67, 0x89],
            [0xDE, 0xAD, 0xBE, 0xEF],
            [0xCA, 0xFE, 0xBA, 0xBE],
        ];
        let mut state = original;
        shift_rows(&mut state);
        inv_shift_rows(&mut state);
        assert_eq!(state, original);
    }

    #[test]
    fn test_mix_columns_roundtrip() {
        let original: State = [
            [0xDB, 0x13, 0x53, 0x45],
            [0xF2, 0x0A, 0x45, 0x7F],
            [0x01, 0x01, 0x01, 0x01],
            [0xC6, 0xC6, 0xC6, 0xC6],
        ];
        let mut state = original;
        mix_columns(&mut state);
        inv_mix_columns(&mut state);
        assert_eq!(state, original);
    }

    #[test]
    fn test_mix_columns_fips_vector() {
        // FIPS-197 §5.1.3 columns: [DB,13,53,45], [F2,0A,22,5C], [01,01,01,01], [C6,C6,C6,C6]
        // In state[row][col]: column c = [state[0][c], state[1][c], state[2][c], state[3][c]]
        let mut state: State = [
            [0xDB, 0xF2, 0x01, 0xC6],
            [0x13, 0x0A, 0x01, 0xC6],
            [0x53, 0x22, 0x01, 0xC6],
            [0x45, 0x5C, 0x01, 0xC6],
        ];
        mix_columns(&mut state);
        assert_eq!(state[0], [0x8E, 0x9F, 0x01, 0xC6]);
        assert_eq!(state[1], [0x4D, 0xDC, 0x01, 0xC6]);
        assert_eq!(state[2], [0xA1, 0x58, 0x01, 0xC6]);
        assert_eq!(state[3], [0xBC, 0x9D, 0x01, 0xC6]);
    }

    #[test]
    fn test_linear_layer_roundtrip() {
        let original: State = [
            [0x12, 0x34, 0x56, 0x78],
            [0x9A, 0xBC, 0xDE, 0xF0],
            [0x11, 0x22, 0x33, 0x44],
            [0x55, 0x66, 0x77, 0x88],
        ];
        let mut state = original;
        linear_layer(&mut state);
        inv_linear_layer(&mut state);
        assert_eq!(state, original);
    }

    #[test]
    fn test_round_fn_roundtrip() {
        let key = [0x2B, 0x7E, 0x15, 0x16, 0x28, 0xAE, 0xD2, 0xA6,
                   0xAB, 0xF7, 0x15, 0x88, 0x09, 0xCF, 0x4F, 0x3C];
        let original: State = [
            [0x32, 0x88, 0x31, 0xE0],
            [0x43, 0x5A, 0x31, 0x37],
            [0xF6, 0x30, 0x98, 0x07],
            [0xA8, 0x8D, 0xA2, 0x34],
        ];
        let mut state = original;
        round_fn(&mut state, &key);
        inv_round_fn(&mut state, &key);
        assert_eq!(state, original);
    }

    #[test]
    fn test_mds_all_submatrices() {
        assert!(verify_mds_all_submatrices());
    }

    #[test]
    fn test_branch_number_5() {
        assert!(verify_branch_number_5());
    }
}
