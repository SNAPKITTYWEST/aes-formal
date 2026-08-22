// Phase 11: AES-256 14-round TTI attack margin analysis.
//
// This module verifies arithmetic margins only. It does not claim a
// practical or formal break of AES-256.

pub const AES_BLOCK_BITS: u32 = 128;
pub const AES256_KEY_BITS: u32 = 256;
pub const AES256_ROUNDS: usize = 14;
pub const SBOX_DIFF_WEIGHT_BITS: u32 = 6;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RoundMargin {
    pub rounds: usize,
    pub min_active_sboxes: u32,
    pub differential_weight_bits: u32,
    pub exceeds_codebook: bool,
    pub exceeds_aes256_key_search: bool,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct AttackFailure {
    pub first_codebook_failure_round: usize,
    pub first_key_search_failure_round: usize,
    pub full_round_margin: RoundMargin,
    pub codebook_margin_bits: u32,
    pub key_search_margin_bits: u32,
}

pub const fn min_active_sboxes(rounds: usize) -> u32 {
    match rounds {
        0 => 0,
        1 => 1,
        2 => 5,
        3 => 9,
        4 => 25,
        5 => 26,
        6 => 30,
        7 => 34,
        8 => 50,
        n => 50 + 6 * ((n - 8) as u32),
    }
}

pub const fn round_margin(rounds: usize) -> RoundMargin {
    let active = min_active_sboxes(rounds);
    let weight = active * SBOX_DIFF_WEIGHT_BITS;
    RoundMargin {
        rounds,
        min_active_sboxes: active,
        differential_weight_bits: weight,
        exceeds_codebook: weight > AES_BLOCK_BITS,
        exceeds_aes256_key_search: weight > AES256_KEY_BITS,
    }
}

pub fn first_failure_round(limit_bits: u32, max_rounds: usize) -> Option<usize> {
    (1..=max_rounds).find(|rounds| round_margin(*rounds).differential_weight_bits > limit_bits)
}

pub fn analyze_tti_aes256_14round() -> AttackFailure {
    let full = round_margin(AES256_ROUNDS);
    AttackFailure {
        first_codebook_failure_round: first_failure_round(AES_BLOCK_BITS, AES256_ROUNDS)
            .expect("AES-256 TTI codebook failure must occur by 14 rounds"),
        first_key_search_failure_round: first_failure_round(AES256_KEY_BITS, AES256_ROUNDS)
            .expect("AES-256 TTI key-search failure must occur by 14 rounds"),
        full_round_margin: full,
        codebook_margin_bits: full.differential_weight_bits - AES_BLOCK_BITS,
        key_search_margin_bits: full.differential_weight_bits - AES256_KEY_BITS,
    }
}

pub fn verify_aes256_14round_margin() -> bool {
    let result = analyze_tti_aes256_14round();
    result.full_round_margin.min_active_sboxes == 86
        && result.full_round_margin.differential_weight_bits == 516
        && result.first_codebook_failure_round == 4
        && result.first_key_search_failure_round == 8
        && result.codebook_margin_bits == 388
        && result.key_search_margin_bits == 260
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_full_14_round_margin() {
        let result = analyze_tti_aes256_14round();
        assert_eq!(result.full_round_margin.min_active_sboxes, 86);
        assert_eq!(result.full_round_margin.differential_weight_bits, 516);
        assert_eq!(result.codebook_margin_bits, 388);
        assert_eq!(result.key_search_margin_bits, 260);
    }

    #[test]
    fn test_first_failure_rounds() {
        let result = analyze_tti_aes256_14round();
        assert_eq!(result.first_codebook_failure_round, 4);
        assert_eq!(result.first_key_search_failure_round, 8);
    }

    #[test]
    fn test_verifier() {
        assert!(verify_aes256_14round_margin());
    }
}

