// Phase 2: Production-grade GF(2^8) with log/antilog tables
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff

/// GF(2^8) with AES polynomial x^8 + x^4 + x^3 + x + 1 (0x11B)
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default)]
pub struct GF256(pub u8);

impl GF256 {
    pub const ZERO: Self = GF256(0);
    pub const ONE:  Self = GF256(1);

    /// Raw multiplication for table generation (const fn)
    const fn gf_mul_raw(mut a: u8, mut b: u8) -> u8 {
        let mut result = 0u8;
        while b != 0 {
            if b & 1 != 0 { result ^= a; }
            b >>= 1;
            a <<= 1;
            if a & 0x80 != 0 { a ^= 0x1B; }
        }
        result
    }

    const fn gen_log_table() -> [u8; 256] {
        let mut table = [0u8; 256];
        let mut x = 1u8;
        let mut i = 0usize;
        while i < 255 {
            table[x as usize] = i as u8;
            x = Self::gf_mul_raw(x, 3);
            i += 1;
        }
        table
    }

    const fn gen_antilog_table() -> [u8; 256] {
        let mut table = [0u8; 256];
        let mut x = 1u8;
        let mut i = 0usize;
        while i < 255 {
            table[i] = x;
            x = Self::gf_mul_raw(x, 3);
            i += 1;
        }
        table[255] = 1;
        table
    }

    const fn gen_inv_table() -> [u8; 256] {
        let mut table = [0u8; 256];
        table[0] = 0;
        let mut i = 1usize;
        while i < 256 {
            let mut j = 1usize;
            while j < 256 {
                if Self::gf_mul_raw(i as u8, j as u8) == 1 {
                    table[i] = j as u8;
                    break;
                }
                j += 1;
            }
            i += 1;
        }
        table
    }

    const LOG_TABLE:     [u8; 256] = Self::gen_log_table();
    const ANTILOG_TABLE: [u8; 256] = Self::gen_antilog_table();
    const INV_TABLE:     [u8; 256] = Self::gen_inv_table();

    #[inline]
    pub fn add(self, other: Self) -> Self { GF256(self.0 ^ other.0) }

    #[inline]
    pub fn mul(self, other: Self) -> Self {
        if self.0 == 0 || other.0 == 0 { return GF256::ZERO; }
        let log_a = Self::LOG_TABLE[self.0 as usize] as u16;
        let log_b = Self::LOG_TABLE[other.0 as usize] as u16;
        GF256(Self::ANTILOG_TABLE[((log_a + log_b) % 255) as usize])
    }

    #[inline]
    pub fn inv(self) -> Self {
        if self.0 == 0 { return GF256::ZERO; }
        GF256(Self::INV_TABLE[self.0 as usize])
    }

    #[inline]
    pub fn pow(self, exp: u16) -> Self {
        if self.0 == 0 { return if exp == 0 { GF256::ONE } else { GF256::ZERO }; }
        let log_a = Self::LOG_TABLE[self.0 as usize] as u32;
        GF256(Self::ANTILOG_TABLE[((log_a * exp as u32) % 255) as usize])
    }

    #[inline]
    pub fn frobenius(self) -> Self { self.pow(2) }
}

impl core::ops::Add for GF256 {
    type Output = Self;
    #[inline] fn add(self, o: Self) -> Self { self.add(o) }
}
impl core::ops::Mul for GF256 {
    type Output = Self;
    #[inline] fn mul(self, o: Self) -> Self { self.mul(o) }
}

/// S-box: S(x) = x⁻¹ ⊕ 0x63
#[inline]
pub fn sbox(x: GF256) -> GF256 {
    if x == GF256::ZERO { GF256(0x63) } else { x.inv().add(GF256(0x63)) }
}

/// Inverse S-box
#[inline]
pub fn inv_sbox(x: GF256) -> GF256 {
    let y = x.add(GF256(0x63));
    if y == GF256::ZERO { GF256::ZERO } else { y.inv() }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test] fn test_add() {
        assert_eq!(GF256(1).add(GF256(1)), GF256(0));
        assert_eq!(GF256(0x57).add(GF256(0x83)), GF256(0xD4));
    }
    #[test] fn test_mul() {
        assert_eq!(GF256(2).mul(GF256(3)), GF256(6));
        assert_eq!(GF256(0x57).mul(GF256(0x83)), GF256(0xC1));
    }
    #[test] fn test_inv() {
        for i in 1..=255u8 {
            assert_eq!(GF256(i).mul(GF256(i).inv()), GF256::ONE);
        }
    }
    #[test] fn test_frobenius() {
        let a = GF256(0x57); let b = GF256(0x83);
        assert_eq!((a.add(b)).frobenius(), a.frobenius().add(b.frobenius()));
    }
    #[test] fn test_sbox() {
        assert_eq!(sbox(GF256(0x00)), GF256(0x63));
        assert_eq!(sbox(GF256(0x53)), GF256(0xED));
        assert_eq!(inv_sbox(sbox(GF256(0x53))), GF256(0x53));
    }
}
