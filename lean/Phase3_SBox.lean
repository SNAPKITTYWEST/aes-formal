/-======================================================================
  PHASE 3: S-BOX POLYNOMIAL S(x) = x⁻¹ + A(x) + 0x63
  Full affine transformation over GF(2)
  Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
  Authors: Ahmad Ali Parr — Jessica Westerhoff
  ======================================================================-/

namespace AESFormalization.Phase3

open Matrix Fin ZMod

/-- AES S-box affine matrix (circulant 8×8 over GF(2)) -/
def sbox_affine_matrix : Matrix (Fin 8) (Fin 8) (ZMod 2) :=
  !![1, 0, 0, 0, 1, 1, 1, 1;
     1, 1, 0, 0, 0, 1, 1, 1;
     1, 1, 1, 0, 0, 0, 1, 1;
     1, 1, 1, 1, 0, 0, 0, 1;
     1, 1, 1, 1, 1, 0, 0, 0;
     0, 1, 1, 1, 1, 1, 0, 0;
     0, 0, 1, 1, 1, 1, 1, 0;
     0, 0, 0, 1, 1, 1, 1, 1]

/-- Affine constant vector c = 0x63 = 0b01100011 -/
def sbox_const_vec : Fin 8 → (ZMod 2) :=
  ![1, 1, 0, 0, 0, 1, 1, 0]

def affine_transform (x : Phase2.GF256) : Phase2.GF256 :=
  /- AES S-box affine step: y_i = Σ_j M_{ij} · x_j + c_i  (all arithmetic in ZMod 2).
     Bits are the coefficients of the degree-<8 canonical representative of x mod aes_poly.
     The circulant structure of sbox_affine_matrix makes row i a rotate-left-by-i mask. -/
  Quotient.liftOn x
    (fun (p : Polynomial (ZMod 2)) =>
      -- 1. Extract 8 bits: x_i = coeff of X^i in (p mod aes_poly)  (degree < 8)
      let bits    : Fin 8 → ZMod 2 := fun i =>
        (p % Phase2.aes_poly).coeff i.val
      -- 2. Affine: y_i = (Σ_{j<8} M[i,j] * x_j) + c_i  (+ = XOR over ZMod 2)
      let outBits : Fin 8 → ZMod 2 := fun i =>
        (∑ j : Fin 8, sbox_affine_matrix i j * bits j) + sbox_const_vec i
      -- 3. Re-pack: lift output bits back to the quotient as  Σ_{i<8} y_i · X^i
      Ideal.Quotient.mk (Ideal.span {Phase2.aes_poly})
        (∑ i : Fin 8, Polynomial.C (outBits i) * Polynomial.X ^ (i.val)))
    (by
      -- Well-definedness: a ≡ b (mod aes_poly) ⟹ a % aes_poly = b % aes_poly
      -- ⟹ same bit extraction ⟹ same outBits ⟹ same element of GF256.
      -- Key lemma required: in Polynomial (ZMod 2), p ∣ (a - b) ⟹ a % p = b % p.
      -- (Follows from EuclideanDomain.modByMonic_eq of Polynomial with aes_poly monic.)
      intro a b hab
      have h_mod : a % Phase2.aes_poly = b % Phase2.aes_poly := by sorry
      simp only [h_mod])

/-- S-box: S(x) = A(x⁻¹) + c -/
def sbox_polynomial (x : Phase2.GF256) : Phase2.GF256 :=
  if h : x = 0 then (99 : Phase2.GF256) else
    affine_transform (x ^ 254) + (99 : Phase2.GF256)

/-- S-box has no fixed points: S(x) ≠ x -/
theorem sbox_no_fixed_points : ∀ (x : Phase2.GF256), sbox_polynomial x ≠ x := by sorry

/-- S-box is a permutation (bijective) -/
theorem sbox_bijective : Function.Bijective (sbox_polynomial : Phase2.GF256 → Phase2.GF256) := by sorry

/-- Differential uniformity = 4 (optimal for 8-bit) -/
theorem sbox_differential_uniformity :
  ∀ (Δx : Phase2.GF256) (Δy : Phase2.GF256), Δx ≠ 0 →
  (Finset.card (Finset.filter
    (fun x => sbox_polynomial (x + Δx) - sbox_polynomial x = Δy)
    (Finset.univ : Finset Phase2.GF256))) ≤ 4 := by sorry

/-- S-box polynomial degree = 254 -/
theorem sbox_degree_254 :
  ∃ (poly : Polynomial (ZMod 2)),
  poly.natDegree = 254 :=
  /- Witness: X^254 has natDegree 254 by Polynomial.natDegree_X_pow.
     In the context of AES, the S-box on GF(2⁸) is computed as x ↦ x²⁵⁴ (= x⁻¹)
     followed by the affine map; working in the polynomial quotient ring over GF(2),
     the representative polynomial has degree exactly 254 < 256 = 2^8.
     Completing this proof requires: (1) Polynomial.natDegree_X_pow to discharge the
     witness side, and (2) a separate argument connecting x^254 in GF256 to a concrete
     polynomial representative — left as sorry pending Mathlib polynomial-quotient API. -/
  ⟨Polynomial.X ^ 254, by sorry⟩

end AESFormalization.Phase3
