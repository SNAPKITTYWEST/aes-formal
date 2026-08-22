/-======================================================================
  PHASE 11: AES-256 14-ROUND TTI ATTACK MARGIN

  This file records arithmetic failure points for a TTI-style
  differential/algebraic attack model on full 14-round AES-256.

  Honest boundary:
    • These theorems prove arithmetic relationships between the stated
      active-S-box lower-bound schedule and attack data exponents.
    • They do NOT prove a new AES-256 lower bound.
    • They do NOT claim AES-256 is broken.
    • They do NOT close C1-C4 from AESProofMeta.lean.

  Model:
    rounds 1..8:  1, 5, 9, 25, 26, 30, 34, 50 active S-boxes
    rounds >= 9:  50 + 6 * (rounds - 8)

  Each active AES S-box contributes differential weight 6 because the
  maximum AES S-box differential probability is 2^-6.
  ======================================================================-/

namespace AESFormalization.Phase11

def aesBlockBits : Nat := 128
def aes256KeyBits : Nat := 256
def aes256Rounds : Nat := 14
def sboxDiffWeightBits : Nat := 6

/-- Conservative active-S-box lower-bound schedule used for margin checks. -/
def minActiveSboxes : Nat → Nat
  | 0 => 0
  | 1 => 1
  | 2 => 5
  | 3 => 9
  | 4 => 25
  | 5 => 26
  | 6 => 30
  | 7 => 34
  | 8 => 50
  | (n + 9) => 50 + 6 * (n + 1)

def differentialWeightBits (rounds : Nat) : Nat :=
  minActiveSboxes rounds * sboxDiffWeightBits

/-- Full 14-round AES-256 activates at least 86 S-boxes in this model. -/
theorem fourteenRoundActiveSboxes :
    minActiveSboxes aes256Rounds = 86 := by
  native_decide

/-- Full 14-round AES-256 gives differential data exponent 86*6 = 516. -/
theorem fourteenRoundDifferentialWeight :
    differentialWeightBits aes256Rounds = 516 := by
  native_decide

/-- The finite-codebook data budget fails first at round 4:
    round 3 has weight 54, round 4 has weight 150 > 128. -/
theorem finiteCodebookFailureAtRound4 :
    differentialWeightBits 3 ≤ aesBlockBits ∧
    differentialWeightBits 4 > aesBlockBits := by
  native_decide

/-- The AES-256 key-search budget fails first at round 8:
    round 7 has weight 204, round 8 has weight 300 > 256. -/
theorem aes256KeySearchFailureAtRound8 :
    differentialWeightBits 7 ≤ aes256KeyBits ∧
    differentialWeightBits 8 > aes256KeyBits := by
  native_decide

/-- Full 14-round data exponent exceeds the finite 128-bit block codebook by 388 bits. -/
theorem fourteenRoundCodebookMarginBits :
    differentialWeightBits aes256Rounds - aesBlockBits = 388 := by
  native_decide

/-- Full 14-round data exponent exceeds AES-256 exhaustive key search by 260 bits. -/
theorem fourteenRoundKeySearchMarginBits :
    differentialWeightBits aes256Rounds - aes256KeyBits = 260 := by
  native_decide

/-- Full 14-round TTI-style differential data demand is beyond AES-256 key-search budget. -/
theorem fourteenRoundTtiFailsAgainstKeyBudget :
    differentialWeightBits aes256Rounds > aes256KeyBits := by
  native_decide

/-- Summary record for the Phase 11 arithmetic model. -/
structure AES256MarginSummary where
  rounds : Nat
  minActive : Nat
  differentialWeight : Nat
  firstCodebookFailureRound : Nat
  firstKeySearchFailureRound : Nat
  codebookMarginBits : Nat
  keySearchMarginBits : Nat
  deriving Repr, DecidableEq

def aes256_14round_margin_summary : AES256MarginSummary := {
  rounds := aes256Rounds,
  minActive := minActiveSboxes aes256Rounds,
  differentialWeight := differentialWeightBits aes256Rounds,
  firstCodebookFailureRound := 4,
  firstKeySearchFailureRound := 8,
  codebookMarginBits := differentialWeightBits aes256Rounds - aesBlockBits,
  keySearchMarginBits := differentialWeightBits aes256Rounds - aes256KeyBits
}

theorem summaryVerified :
    aes256_14round_margin_summary = {
      rounds := 14,
      minActive := 86,
      differentialWeight := 516,
      firstCodebookFailureRound := 4,
      firstKeySearchFailureRound := 8,
      codebookMarginBits := 388,
      keySearchMarginBits := 260
    } := by
  native_decide

end AESFormalization.Phase11
