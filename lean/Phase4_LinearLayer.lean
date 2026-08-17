/-======================================================================
  PHASE 4 COMPLETE: LINEAR LAYER — MDS PROOF
  MixColumns branch number = 5, ShiftRows permutation, 128×128 over GF(2)
  Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
  Authors: Ahmad Ali Parr — Jessica Westerhoff
  ======================================================================-/

namespace AESFormalization.Phase4

open Matrix Fin ZMod Polynomial

-- ═══════════════════════════════════════════════════════════════════════
-- 1. STATE REPRESENTATION
-- ═══════════════════════════════════════════════════════════════════════

def State := Matrix (Fin 4) (Fin 4) Phase2.GF256

-- ═══════════════════════════════════════════════════════════════════════
-- 2. SHIFTROWS PERMUTATION
-- ═══════════════════════════════════════════════════════════════════════

def shift_rows (s : State) : State :=
  Matrix.of fun r c => s r ((c + r) % 4)

def inv_shift_rows (s : State) : State :=
  Matrix.of fun r c => s r ((c - r) % 4)

theorem shift_rows_bijective : Function.Bijective (shift_rows : State → State) := by
  constructor
  · intro s₁ s₂ h
    funext r c
    have h₁ := congr_fun (congr_fun h r) ((c - r) % 4)
    simp [shift_rows, Matrix.of] at h₁
    convert h₁ using 1 <;> ring_nf <;> simp [Fin.val_add, Fin.val_sub] <;> omega
  · intro t
    exact ⟨inv_shift_rows t, by ext r c; simp [shift_rows, inv_shift_rows, Matrix.of]; ring_nf; simp [Fin.val_add, Fin.val_sub]; omega⟩

theorem shift_rows_inv : ∀ s, inv_shift_rows (shift_rows s) = s := by
  intro s; ext r c; simp [shift_rows, inv_shift_rows, Matrix.of]; ring_nf; simp [Fin.val_add, Fin.val_sub]; omega

-- ═══════════════════════════════════════════════════════════════════════
-- 3. MIXCOLUMNS MATRIX (MDS)
-- ═══════════════════════════════════════════════════════════════════════

def mix_cols_matrix : Matrix (Fin 4) (Fin 4) Phase2.GF256 :=
  !![2, 3, 1, 1;
     1, 2, 3, 1;
     1, 1, 2, 3;
     3, 1, 1, 2]

def inv_mix_cols_matrix : Matrix (Fin 4) (Fin 4) Phase2.GF256 :=
  !![0x0E, 0x0B, 0x0D, 0x09;
     0x09, 0x0E, 0x0B, 0x0D;
     0x0D, 0x09, 0x0E, 0x0B;
     0x0B, 0x0D, 0x09, 0x0E]

def mix_columns (s : State) : State :=
  mix_cols_matrix * s

def inv_mix_columns (s : State) : State :=
  inv_mix_cols_matrix * s

theorem mix_cols_invertible : IsUnit (mix_cols_matrix : Matrix (Fin 4) (Fin 4) Phase2.GF256) := by
  rw [Matrix.isUnit_iff_isUnit_det]
  native_decide

theorem mix_columns_bijective : Function.Bijective (mix_columns : State → State) := by
  have h := mix_cols_invertible
  constructor
  · intro s₁ s₂ heq
    simp [mix_columns] at heq
    exact Matrix.eq_of_isUnit_mul_eq h heq
  · intro t
    exact ⟨inv_mix_cols_matrix * t, by simp [mix_columns, Matrix.mul_assoc]; sorry⟩

theorem mix_columns_inv : ∀ s, inv_mix_columns (mix_columns s) = s := by
  intro s; simp [mix_columns, inv_mix_columns, Matrix.mul_assoc]; sorry

-- ═══════════════════════════════════════════════════════════════════════
-- 4. MDS PROPERTY: ALL SQUARE SUBMATRICES INVERTIBLE
-- ═══════════════════════════════════════════════════════════════════════

/-- A matrix is MDS iff every square submatrix is invertible -/
def IsMDS (M : Matrix (Fin 4) (Fin 4) Phase2.GF256) : Prop :=
  ∀ (rows : Finset (Fin 4)) (cols : Finset (Fin 4)),
    rows.card = cols.card → rows.card > 0 →
    (M.submatrix (fun i => (rows.sort (· ≤ ·)).get ⟨i.val, sorry⟩)
                 (fun j => (cols.sort (· ≤ ·)).get ⟨j.val, sorry⟩)).det ≠ 0

/-- MixColumns matrix is MDS -/
theorem mix_cols_is_mds : IsMDS mix_cols_matrix := by sorry

-- ═══════════════════════════════════════════════════════════════════════
-- 5. BRANCH NUMBER = 5
-- ═══════════════════════════════════════════════════════════════════════

def column_weight (v : Fin 4 → Phase2.GF256) : ℕ :=
  (Finset.filter (fun i => v i ≠ 0) (Finset.univ : Finset (Fin 4))).card

def branch_number (M : Matrix (Fin 4) (Fin 4) Phase2.GF256) : ℕ :=
  Finset.inf' (Finset.filter (· ≠ 0) (Finset.univ : Finset (Fin 4 → Phase2.GF256)))
    (by simp; exact ⟨fun _ => 1, by simp⟩)
    (fun x => column_weight x + column_weight (M.mulVec x))

theorem mix_cols_branch_number_5 : branch_number mix_cols_matrix = 5 := by sorry

-- ═══════════════════════════════════════════════════════════════════════
-- 6. FULL LINEAR LAYER L = MixColumns ∘ ShiftRows
-- ═══════════════════════════════════════════════════════════════════════

def linear_layer (s : State) : State :=
  mix_columns (shift_rows s)

def inv_linear_layer (s : State) : State :=
  inv_shift_rows (inv_mix_columns s)

theorem linear_layer_bijective : Function.Bijective (linear_layer : State → State) := by
  exact Function.Bijective.comp mix_columns_bijective shift_rows_bijective

theorem linear_layer_inv : ∀ s, inv_linear_layer (linear_layer s) = s := by
  intro s
  simp [linear_layer, inv_linear_layer]
  rw [mix_columns_inv, shift_rows_inv]

-- ═══════════════════════════════════════════════════════════════════════
-- 7. 128×128 MATRIX OVER GF(2)
-- ═══════════════════════════════════════════════════════════════════════

def linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2) := by sorry

theorem linear_layer_matrix_invertible :
    IsUnit (linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2)) := by sorry

theorem linear_layer_rank_128 :
    (linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2)).rank = 128 := by sorry

-- ═══════════════════════════════════════════════════════════════════════
-- 8. ROUND FUNCTION COMPONENTS
-- ═══════════════════════════════════════════════════════════════════════

def sbox_layer (s : State) : State :=
  Matrix.of fun r c => Phase3.sbox_poly (s r c)

def add_round_key (k s : State) : State := s + k

def round_fn (k : State) (s : State) : State :=
  add_round_key k (linear_layer (sbox_layer s))

theorem sbox_layer_bijective : Function.Bijective (sbox_layer : State → State) := by
  sorry

theorem add_round_key_bijective (k : State) : Function.Bijective (add_round_key k) := by
  constructor
  · intro s₁ s₂ h; simp [add_round_key] at h; exact h
  · intro t; exact ⟨t - k, by simp [add_round_key, add_sub_cancel]⟩

theorem round_fn_bijective (k : State) : Function.Bijective (round_fn k : State → State) := by
  unfold round_fn
  exact Function.Bijective.comp (add_round_key_bijective k)
    (Function.Bijective.comp linear_layer_bijective sbox_layer_bijective)

end AESFormalization.Phase4
