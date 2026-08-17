// Phase 3 Complete: S-box Polynomial with Full Affine Transform
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

use crate::gf256::GF256;

// AES affine matrix (each row stored LSB-first as a byte)
// Row i: bits at positions (i, i+1, i+2, i+3, i+4) mod 8 are set
const AES_AFFINE: [u8; 8] = [
    0xF1, // 1111_0001: cols 0,4,5,6,7
    0xE3, // 1110_0011: cols 0,1,5,6,7
    0xC7, // 1100_0111: cols 0,1,2,6,7
    0x8F, // 1000_1111: cols 0,1,2,3,7
    0x1F, // 0001_1111: cols 0,1,2,3,4
    0x3E, // 0011_1110: cols 1,2,3,4,5
    0x7C, // 0111_1100: cols 2,3,4,5,6
    0xF8, // 1111_1000: cols 3,4,5,6,7
];

// Inverse affine matrix (precomputed)
const AES_INV_AFFINE: [u8; 8] = [
    0xA4, // 1010_0100
    0x49, // 0100_1001
    0x92, // 1001_0010
    0x25, // 0010_0101
    0x4A, // 0100_1010
    0x94, // 1001_0100
    0x29, // 0010_1001
    0x52, // 0101_0010
];

const AFFINE_CONST: u8 = 0x63;

#[inline]
fn gf2_mat_vec(matrix: &[u8; 8], x: u8) -> u8 {
    let mut result = 0u8;
    for i in 0..8 {
        let dot = (matrix[i] & x).count_ones() & 1;
        result |= (dot as u8) << i;
    }
    result
}

#[inline]
pub fn affine_transform(x: u8) -> u8 {
    gf2_mat_vec(&AES_AFFINE, x) ^ AFFINE_CONST
}

#[inline]
pub fn inv_affine_transform(y: u8) -> u8 {
    gf2_mat_vec(&AES_INV_AFFINE, y ^ AFFINE_CONST)
}

/// S-box: S(x) = A(x⁻¹) for x ≠ 0, S(0) = A(0) = 0x63
pub fn sbox_full(x: GF256) -> GF256 {
    if x == GF256::ZERO {
        GF256(AFFINE_CONST)
    } else {
        GF256(affine_transform(x.inv().0))
    }
}

/// Inverse S-box: S⁻¹(y) = (A⁻¹(y))⁻¹
pub fn inv_sbox_full(y: GF256) -> GF256 {
    if y == GF256(AFFINE_CONST) {
        GF256::ZERO
    } else {
        let x = inv_affine_transform(y.0);
        GF256(x).inv()
    }
}

// Precomputed S-box table (generated at runtime for now; const requires pub INV_TABLE)
pub fn gen_sbox_table() -> [u8; 256] {
    let mut table = [0u8; 256];
    table[0] = AFFINE_CONST;
    for i in 1..256usize {
        let inv = GF256(i as u8).inv().0;
        table[i] = gf2_mat_vec(&AES_AFFINE, inv) ^ AFFINE_CONST;
    }
    table
}


// ═══════════════════════════════════════════════════════════════════════
// DIFFERENTIAL ANALYSIS
// ═══════════════════════════════════════════════════════════════════════

pub fn compute_ddt() -> [[u8; 256]; 256] {
    let mut ddt = [[0u8; 256]; 256];
    for dx in 1u16..256 {
        for x in 0u16..256 {
            let sx = sbox_full(GF256(x as u8));
            let sxdx = sbox_full(GF256(x as u8).add(GF256(dx as u8)));
            let dy = sx.add(sxdx).0;
            ddt[dx as usize][dy as usize] = ddt[dx as usize][dy as usize].saturating_add(1);
        }
    }
    ddt
}

pub fn max_ddt_entry() -> u8 {
    let ddt = compute_ddt();
    let mut max_val = 0u8;
    for dx in 1..256 {
        for dy in 0..256 {
            if ddt[dx][dy] > max_val {
                max_val = ddt[dx][dy];
            }
        }
    }
    max_val
}

// ═══════════════════════════════════════════════════════════════════════
// LINEAR ANALYSIS
// ═══════════════════════════════════════════════════════════════════════

#[inline]
fn parity8(x: u8) -> u8 {
    x.count_ones() as u8 & 1
}

pub fn compute_lat() -> [[i16; 256]; 256] {
    let mut lat = [[0i16; 256]; 256];
    for a in 0u16..256 {
        for b in 0u16..256 {
            let mut count: i16 = 0;
            for x in 0u16..256 {
                let sx = sbox_full(GF256(x as u8)).0;
                let p = parity8((a as u8) & (x as u8)) ^ parity8((b as u8) & sx);
                if p == 0 { count += 1; }
            }
            lat[a as usize][b as usize] = count - 128;
        }
    }
    lat
}

pub fn max_lat_bias() -> i16 {
    let lat = compute_lat();
    let mut max_bias: i16 = 0;
    for a in 0..256 {
        for b in 0..256 {
            if a == 0 && b == 0 { continue; }
            let bias = lat[a][b].abs();
            if bias > max_bias { max_bias = bias; }
        }
    }
    max_bias
}

// ═══════════════════════════════════════════════════════════════════════
// ALGEBRAIC DEGREE (ANF via Möbius transform)
// ═══════════════════════════════════════════════════════════════════════

pub fn compute_algebraic_degree() -> [u8; 8] {
    let mut degrees = [0u8; 8];
    for bit in 0..8u8 {
        let mut truth_table = [0u8; 256];
        for x in 0..256 {
            truth_table[x] = (sbox_full(GF256(x as u8)).0 >> bit) & 1;
        }
        // Möbius transform
        let mut anf = truth_table;
        for i in 0..8 {
            for mask in 0..256usize {
                if mask & (1 << i) != 0 {
                    anf[mask] ^= anf[mask ^ (1 << i)];
                }
            }
        }
        let mut max_deg = 0u8;
        for mask in 0..256usize {
            if anf[mask] != 0 {
                let deg = (mask as u8).count_ones() as u8;
                if deg > max_deg { max_deg = deg; }
            }
        }
        degrees[bit as usize] = max_deg;
    }
    degrees
}

// ═══════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_sbox_fips197_vectors() {
        assert_eq!(sbox_full(GF256(0x00)).0, 0x63);
        assert_eq!(sbox_full(GF256(0x01)).0, 0x7C);
        assert_eq!(sbox_full(GF256(0x53)).0, 0xED);
        assert_eq!(sbox_full(GF256(0xFF)).0, 0x16);
        assert_eq!(sbox_full(GF256(0x10)).0, 0xCA);
        assert_eq!(sbox_full(GF256(0xFE)).0, 0xBB);
    }

    #[test]
    fn test_inv_sbox_fips197_vectors() {
        assert_eq!(inv_sbox_full(GF256(0x63)).0, 0x00);
        assert_eq!(inv_sbox_full(GF256(0x7C)).0, 0x01);
        assert_eq!(inv_sbox_full(GF256(0xED)).0, 0x53);
        assert_eq!(inv_sbox_full(GF256(0x16)).0, 0xFF);
    }

    #[test]
    fn test_sbox_bijection() {
        let mut seen = [false; 256];
        for i in 0..256u16 {
            let out = sbox_full(GF256(i as u8)).0;
            assert!(!seen[out as usize], "collision at input {}", i);
            seen[out as usize] = true;
        }
    }

    #[test]
    fn test_sbox_no_fixed_points() {
        for i in 0..256u16 {
            assert_ne!(sbox_full(GF256(i as u8)).0, i as u8,
                "fixed point at {}", i);
        }
    }

    #[test]
    fn test_sbox_inv_roundtrip() {
        for i in 0..256u16 {
            let x = GF256(i as u8);
            assert_eq!(inv_sbox_full(sbox_full(x)), x, "S⁻¹(S(x)) ≠ x at {}", i);
            assert_eq!(sbox_full(inv_sbox_full(x)), x, "S(S⁻¹(x)) ≠ x at {}", i);
        }
    }

    #[test]
    fn test_inv_affine_roundtrip() {
        for i in 0..256u16 {
            let x = i as u8;
            assert_eq!(inv_affine_transform(affine_transform(x)), x,
                "A⁻¹(A(x)) ≠ x at {}", i);
            assert_eq!(affine_transform(inv_affine_transform(x)), x,
                "A(A⁻¹(x)) ≠ x at {}", i);
        }
    }

    #[test]
    fn test_max_differential_4() {
        assert_eq!(max_ddt_entry(), 4);
    }

    #[test]
    fn test_max_linear_bias_16() {
        assert_eq!(max_lat_bias(), 16);
    }

    #[test]
    fn test_algebraic_degree_7() {
        let degrees = compute_algebraic_degree();
        for (bit, &deg) in degrees.iter().enumerate() {
            assert_eq!(deg, 7, "output bit {} has degree {}, expected 7", bit, deg);
        }
    }
}
