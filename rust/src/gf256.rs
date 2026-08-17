// Phase 2 Complete: Production GF(2^8) with full verification
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff

/// GF(2^8) with AES polynomial x^8 + x^4 + x^3 + x + 1 (0x11B)
#[derive(Clone, Copy, PartialEq, Eq, Debug, Default, Hash)]
pub struct GF256(pub u8);

impl GF256 {
    pub const ZERO: Self = GF256(0);
    pub const ONE:  Self = GF256(1);

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
        let mut t = [0u8; 256];
        let mut x = 1u8; let mut i = 0usize;
        while i < 255 { t[x as usize] = i as u8; x = Self::gf_mul_raw(x, 3); i += 1; }
        t
    }
    const fn gen_antilog_table() -> [u8; 256] {
        let mut t = [0u8; 256];
        let mut x = 1u8; let mut i = 0usize;
        while i < 255 { t[i] = x; x = Self::gf_mul_raw(x, 3); i += 1; }
        t[255] = 1; t
    }
    const fn gen_inv_table() -> [u8; 256] {
        let mut t = [0u8; 256];
        t[0] = 0; t[1] = 1;
        let mut i = 2usize;
        while i < 256 {
            let mut j = 1usize;
            while j < 256 {
                if Self::gf_mul_raw(i as u8, j as u8) == 1 { t[i] = j as u8; break; }
                j += 1;
            }
            i += 1;
        }
        t
    }
    const fn gen_frobenius_table() -> [u8; 256] {
        let mut t = [0u8; 256]; let mut i = 0usize;
        while i < 256 { t[i] = Self::gf_mul_raw(i as u8, i as u8); i += 1; }
        t
    }
    const fn gen_mul_table() -> [[u8; 256]; 256] {
        let mut t = [[0u8; 256]; 256];
        let mut i = 0usize;
        while i < 256 {
            let mut j = 0usize;
            while j < 256 { t[i][j] = Self::gf_mul_raw(i as u8, j as u8); j += 1; }
            i += 1;
        }
        t
    }

    const LOG_TABLE:      [u8; 256]        = Self::gen_log_table();
    const ANTILOG_TABLE:  [u8; 256]        = Self::gen_antilog_table();
    const INV_TABLE:      [u8; 256]        = Self::gen_inv_table();
    const FROBENIUS_TABLE:[u8; 256]        = Self::gen_frobenius_table();
    const MUL_TABLE:      [[u8; 256]; 256] = Self::gen_mul_table();

    #[inline] pub fn add(self, o: Self) -> Self { GF256(self.0 ^ o.0) }

    #[inline]
    pub fn mul(self, o: Self) -> Self {
        if self.0 == 0 || o.0 == 0 { return GF256::ZERO; }
        let la = Self::LOG_TABLE[self.0 as usize] as u16;
        let lb = Self::LOG_TABLE[o.0 as usize] as u16;
        GF256(Self::ANTILOG_TABLE[((la + lb) % 255) as usize])
    }

    #[inline]
    pub fn inv(self) -> Self {
        if self.0 == 0 { GF256::ZERO } else { GF256(Self::INV_TABLE[self.0 as usize]) }
    }

    #[inline]
    pub fn pow(self, exp: u16) -> Self {
        if self.0 == 0 { return if exp == 0 { GF256::ONE } else { GF256::ZERO }; }
        let la = Self::LOG_TABLE[self.0 as usize] as u32;
        GF256(Self::ANTILOG_TABLE[((la * exp as u32) % 255) as usize])
    }

    #[inline] pub fn frobenius(self) -> Self { GF256(Self::FROBENIUS_TABLE[self.0 as usize]) }
    #[inline] pub fn mul_table(self, o: Self) -> Self { GF256(Self::MUL_TABLE[self.0 as usize][o.0 as usize]) }
}

impl core::ops::Add    for GF256 { type Output=Self; #[inline] fn add(self,o:Self)->Self{self.add(o)} }
impl core::ops::AddAssign for GF256 { #[inline] fn add_assign(&mut self,o:Self){*self=self.add(o)} }
impl core::ops::Mul    for GF256 { type Output=Self; #[inline] fn mul(self,o:Self)->Self{self.mul(o)} }
impl core::ops::MulAssign for GF256 { #[inline] fn mul_assign(&mut self,o:Self){*self=self.mul(o)} }

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

    #[test] fn test_add_commutative() {
        for a in 0..=255u8 { for b in 0..=255u8 {
            assert_eq!((GF256(a)+GF256(b)).0, (GF256(b)+GF256(a)).0);
        }}
    }
    #[test] fn test_add_identity() {
        for a in 0..=255u8 { assert_eq!((GF256(a)+GF256::ZERO).0, a); }
    }
    #[test] fn test_add_self_zero() {
        for a in 0..=255u8 { assert_eq!((GF256(a)+GF256(a)).0, 0); }
    }
    #[test] fn test_mul_inverse() {
        for a in 1..=255u8 { assert_eq!((GF256(a)*GF256(a).inv()).0, 1); }
    }
    #[test] fn test_inv_pow254() {
        for a in 1..=255u8 { assert_eq!(GF256(a).inv().0, GF256(a).pow(254).0); }
    }
    #[test] fn test_frobenius_additive() {
        for a in 0..=255u8 { for b in 0..=255u8 {
            assert_eq!((GF256(a)+GF256(b)).frobenius().0,
                       (GF256(a).frobenius()+GF256(b).frobenius()).0);
        }}
    }
    #[test] fn test_frobenius_multiplicative() {
        for a in 0..=255u8 { for b in 0..=255u8 {
            assert_eq!((GF256(a)*GF256(b)).frobenius().0,
                       (GF256(a).frobenius()*GF256(b).frobenius()).0);
        }}
    }
    #[test] fn test_mul_table_matches() {
        for a in 0..=255u8 { for b in 0..=255u8 {
            assert_eq!((GF256(a)*GF256(b)).0, GF256(a).mul_table(GF256(b)).0);
        }}
    }
    #[test] fn test_distributive() {
        for a in 0..=15u8 { for b in 0..=15u8 { for c in 0..=15u8 {
            let x=GF256(a*17); let y=GF256(b*17); let z=GF256(c*17);
            assert_eq!((x*(y+z)).0, ((x*y)+(x*z)).0);
        }}}
    }
    #[test] fn test_sbox_vectors() {
        assert_eq!(sbox(GF256(0x00)), GF256(0x63));
        assert_eq!(sbox(GF256(0x53)), GF256(0xED));
        assert_eq!(inv_sbox(sbox(GF256(0x53))), GF256(0x53));
    }
    #[test] fn test_sbox_bijection() {
        let mut seen = [false; 256];
        for a in 0..=255u8 { let out = sbox(GF256(a)).0; assert!(!seen[out as usize]); seen[out as usize]=true; }
    }
}
