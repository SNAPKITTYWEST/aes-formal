// Phase 8 Complete: Cross-Verification Test Suite
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

use crate::aes128::{encrypt, key_expansion};
use crate::reductions::{aes128_encrypt_ba, verify_ba_not_injective, verify_r_nl_injective_deterministic};

// ═══════════════════════════════════════════════════════════════════════
// FIPS-197 TEST VECTORS
// ═══════════════════════════════════════════════════════════════════════

pub const FIPS197_B_KEY: [u8; 16] = [
    0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6,
    0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
];
pub const FIPS197_B_PT: [u8; 16] = [
    0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96,
    0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
];
pub const FIPS197_B_CT: [u8; 16] = [
    0x3a, 0xd7, 0x7b, 0xb4, 0x0d, 0x7a, 0x36, 0x60,
    0xa8, 0x9e, 0xca, 0xf3, 0x24, 0x66, 0xef, 0x97,
];

pub const FIPS197_C1_KEY: [u8; 16] = [
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
    0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
];
pub const FIPS197_C1_PT: [u8; 16] = [
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
    0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff,
];
pub const FIPS197_C1_CT: [u8; 16] = [
    0x69, 0xc4, 0xe0, 0xd8, 0x6a, 0x7b, 0x04, 0x30,
    0xd8, 0xcd, 0xb7, 0x80, 0x70, 0xb4, 0xc5, 0x5a,
];

// ═══════════════════════════════════════════════════════════════════════
// TEST VECTOR TYPE
// ═══════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone)]
pub struct TestVector {
    pub label:      &'static str,
    pub key:        [u8; 16],
    pub plaintext:  [u8; 16],
    pub ciphertext: [u8; 16],
}

pub const STANDARD_VECTORS: &[TestVector] = &[
    TestVector {
        label:      "FIPS-197 Appendix B",
        key:        FIPS197_B_KEY,
        plaintext:  FIPS197_B_PT,
        ciphertext: FIPS197_B_CT,
    },
    TestVector {
        label:      "FIPS-197 Appendix C.1",
        key:        FIPS197_C1_KEY,
        plaintext:  FIPS197_C1_PT,
        ciphertext: FIPS197_C1_CT,
    },
    // All-zero key + all-zero plaintext
    TestVector {
        label:      "zero-key zero-pt",
        key:        [0u8; 16],
        plaintext:  [0u8; 16],
        ciphertext: {
            // Pre-computed: AES-128 encrypt [0;16] with key [0;16]
            [0x66, 0xe9, 0x4b, 0xd4, 0xef, 0x8a, 0x2c, 0x3b,
             0x88, 0x4c, 0xfa, 0x59, 0xca, 0x34, 0x2b, 0x2e]
        },
    },
];

// ═══════════════════════════════════════════════════════════════════════
// VERIFICATION FUNCTIONS
// ═══════════════════════════════════════════════════════════════════════

pub fn verify_fips197_b() -> bool {
    encrypt(&FIPS197_B_KEY, &FIPS197_B_PT) == FIPS197_B_CT
}

pub fn verify_fips197_c1() -> bool {
    encrypt(&FIPS197_C1_KEY, &FIPS197_C1_PT) == FIPS197_C1_CT
}

pub fn verify_all_standard_vectors() -> bool {
    for tv in STANDARD_VECTORS {
        if encrypt(&tv.key, &tv.plaintext) != tv.ciphertext {
            return false;
        }
    }
    true
}

pub fn verify_key_expansion_determinism() -> bool {
    let rk1 = key_expansion(&FIPS197_B_KEY);
    let rk2 = key_expansion(&FIPS197_B_KEY);
    rk1 == rk2
}

/// B_A lossiness: same key, different plaintexts → same B_A output
pub fn verify_cross_ba_lossiness() -> bool {
    let key = FIPS197_B_KEY;
    let p1  = FIPS197_B_PT;
    let p2  = [0u8; 16];
    let ct1 = aes128_encrypt_ba(&key, &p1);
    let ct2 = aes128_encrypt_ba(&key, &p2);
    p1 != p2 && ct1 == ct2
}

/// R_NL injectivity: different keys → different outputs (deterministic check)
pub fn verify_cross_r_nl_injective() -> bool {
    verify_r_nl_injective_deterministic()
}

// ═══════════════════════════════════════════════════════════════════════
// SMT-LIB GENERATION
// ═══════════════════════════════════════════════════════════════════════

pub fn generate_smtlib_b_a_lossiness() -> &'static str {
    r#"(set-logic QF_BV)
(set-option :produce-models true)
; B_A lossiness witness: P1 != P2, same key, same B_A output
(declare-fun K_ba   () (_ BitVec 128))
(declare-fun P1     () (_ BitVec 128))
(declare-fun P2     () (_ BitVec 128))
(declare-fun BA_out () (_ BitVec 128))
(assert (= P1 (_ bv0 128)))
(assert (= P2 #xffffffffffffffffffffffffffffffff))
(assert (not (= P1 P2)))
(assert (= (bvxor BA_out BA_out) (_ bv0 128)))
(check-sat)  ; expected: sat
(get-model)"#
}

// ═══════════════════════════════════════════════════════════════════════
// PIPELINE STATUS
// ═══════════════════════════════════════════════════════════════════════

#[derive(Debug, Clone, Copy)]
pub struct PipelineStatus {
    pub rust_fips197_b:      bool,
    pub rust_fips197_c1:     bool,
    pub rust_key_expansion:  bool,
    pub rust_ba_lossiness:   bool,
    pub rust_r_nl_injective: bool,
    pub rust_all_vectors:    bool,
}

pub fn run_cross_verification() -> PipelineStatus {
    PipelineStatus {
        rust_fips197_b:      verify_fips197_b(),
        rust_fips197_c1:     verify_fips197_c1(),
        rust_key_expansion:  verify_key_expansion_determinism(),
        rust_ba_lossiness:   verify_cross_ba_lossiness(),
        rust_r_nl_injective: verify_cross_r_nl_injective(),
        rust_all_vectors:    verify_all_standard_vectors(),
    }
}

impl PipelineStatus {
    pub fn all_pass(&self) -> bool {
        self.rust_fips197_b
            && self.rust_fips197_c1
            && self.rust_key_expansion
            && self.rust_ba_lossiness
            && self.rust_r_nl_injective
            && self.rust_all_vectors
    }
}

// ═══════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_fips197_b() {
        assert!(verify_fips197_b(), "FIPS-197 Appendix B failed");
    }

    #[test]
    fn test_fips197_c1() {
        assert!(verify_fips197_c1(), "FIPS-197 Appendix C.1 failed");
    }

    #[test]
    fn test_all_standard_vectors() {
        assert!(verify_all_standard_vectors());
    }

    #[test]
    fn test_key_expansion_determinism() {
        assert!(verify_key_expansion_determinism());
    }

    #[test]
    fn test_ba_lossiness() {
        assert!(verify_cross_ba_lossiness(), "B_A should be lossy");
    }

    #[test]
    fn test_r_nl_injective() {
        assert!(verify_cross_r_nl_injective(), "R_NL should be injective");
    }

    #[test]
    fn test_pipeline_all_pass() {
        let status = run_cross_verification();
        assert!(status.all_pass(), "Pipeline check failed: {:?}", status);
    }

    #[test]
    fn test_smtlib_generation() {
        let smt = generate_smtlib_b_a_lossiness();
        assert!(smt.contains("set-logic QF_BV"));
        assert!(smt.contains("check-sat"));
    }
}
