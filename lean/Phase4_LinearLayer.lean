/-======================================================================
  PHASE 4: LINEAR LAYER — MDS PROOF
  MixColumns is Maximum Distance Separable
  Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
  Authors: Ahmad Ali Parr — Jessica Westerhoff
  ======================================================================-/

namespace AESFormalization.Phase4

open Matrix Fin ZMod

def mix_cols_matrix : Matrix (Fin 4) (Fin 4) Phase2.GF256 :=
  !![2, 3, 1, 1;
     1, 2, 3, 1;
     1, 1, 2, 3;
     3, 1, 1, 2]

-- ═══════════════════════════════════════════════════════════════════════
-- MDS PROPERTY: All square submatrices invertible
-- ═══════════════════════════════════════════════════════════════════════

/-- A matrix is MDS iff every square submatrix is invertible -/
def IsMDS {m n : Type*} [Fintype m] [Fintype n]
    (M : Matrix m n Phase2.GF256) : Prop :=
  ∀ (rows : Finset m) (cols : Finset n),
    rows.card = cols.card → rows.card > 0 →
    IsUnit (M.submatrix
      (fun (i : rows) _ => i.1)
      (fun (j : cols) _ => j.1) : Matrix rows cols Phase2.GF256)

/-- MixColumns matrix is MDS -/
theorem mix_cols_is_mds : IsMDS mix_cols_matrix := by sorry

-- ═══════════════════════════════════════════════════════════════════════
-- BRANCH NUMBER = 5
-- ═══════════════════════════════════════════════════════════════════════

def branch_number (M : Matrix (Fin 4) (Fin 4) Phase2.GF256) : ℕ :=
  Finset.inf' Finset.univ ⟨Finset.univ.choose (fun _ => True) trivial, trivial⟩
    (fun x => if x = 0 then 5 else
      (Finset.filter (fun i => x i ≠ 0) Finset.univ).card +
      (Finset.filter (fun i => (M.mulVec x) i ≠ 0) Finset.univ).card)

theorem mix_cols_branch_number : branch_number mix_cols_matrix = 5 := by sorry

-- ═══════════════════════════════════════════════════════════════════════
-- FULL 128×128 LINEAR LAYER OVER GF(2)
-- ═══════════════════════════════════════════════════════════════════════

def linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2) := by sorry

theorem linear_layer_invertible :
    IsUnit (linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2)) := by sorry

theorem linear_layer_rank_128 :
    (linear_layer_matrix : Matrix (Fin 128) (Fin 128) (ZMod 2)).rank = 128 := by sorry

end AESFormalization.Phase4
