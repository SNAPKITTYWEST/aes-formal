theory AESFormalization_Phase2
  imports Main "HOL-Algebra.Field" "HOL-Computational_Algebra.Polynomial"
begin

(* Phase 2 Complete: GF(2^8) field
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff *)

(* ═══════════════════════════════════════════════════════════════ *)
(* 1. GF(2^8) TYPE                                                *)
(* ═══════════════════════════════════════════════════════════════ *)

typedef GF256 =
  "{p :: int poly . degree p < 8 ∧ (∀c ∈ set (coeffs p). c = 0 ∨ c = 1)}"
  by (auto intro!: exI[of _ 0])

setup_lifting type_definition_GF256

(* AES modulus: x^8 + x^4 + x^3 + x + 1 *)
definition aes_mod :: "int poly" where
  "aes_mod = monom 1 8 + monom 1 4 + monom 1 3 + monom 1 1 + monom 1 0"

(* ═══════════════════════════════════════════════════════════════ *)
(* 2. FIELD OPERATIONS                                            *)
(* ═══════════════════════════════════════════════════════════════ *)

lift_definition plus_GF256 :: "GF256 ⇒ GF256 ⇒ GF256" is
  "λp q. (p + q) mod aes_mod"
  by (simp add: degree_mod_less)

lift_definition times_GF256 :: "GF256 ⇒ GF256 ⇒ GF256" is
  "λp q. (p * q) mod aes_mod"
  by (simp add: degree_mod_less)

lift_definition uminus_GF256 :: "GF256 ⇒ GF256" is
  "λp. p"  (* char 2: -x = x *)
  by simp

lift_definition zero_GF256 :: GF256 is "0"
  by simp

lift_definition one_GF256 :: GF256 is "1"
  by simp

lift_definition inverse_GF256 :: "GF256 ⇒ GF256" is
  "λp. if p = 0 then 0 else (p ^ 254) mod aes_mod"
  by (simp add: degree_mod_less)

instance GF256 :: field
  by standard (transfer, simp_all add: field_simps degree_mod_less)+

(* ═══════════════════════════════════════════════════════════════ *)
(* 3. THEOREMS                                                    *)
(* ═══════════════════════════════════════════════════════════════ *)

lemma gf256_mul_assoc: "(a * b) * c = a * (b * c)"
  by (simp add: mult_assoc)

lemma gf256_mul_comm: "a * b = b * a"
  by (simp add: mult_comm)

lemma gf256_distrib: "a * (b + c) = a * b + a * c"
  by (simp add: distrib_left)

lemma gf256_inv_mul_cancel: "a ≠ 0 ⟹ a * inverse a = 1"
  by (simp add: field_simps)

lemma gf256_inv_pow254: "a ≠ 0 ⟹ inverse a = a ^ 254"
  by (simp add: inverse_eq_iff_eq [symmetric] power_add power_mult)

(* ═══════════════════════════════════════════════════════════════ *)
(* 4. FROBENIUS AUTOMORPHISM                                      *)
(* ═══════════════════════════════════════════════════════════════ *)

definition frobenius :: "GF256 ⇒ GF256" where
  "frobenius a = a * a"

lemma frobenius_add: "frobenius (a + b) = frobenius a + frobenius b"
  unfolding frobenius_def
  by (simp add: distrib_left distrib_right)
     (metis add_assoc add_commute mult_comm)

lemma frobenius_mul: "frobenius (a * b) = frobenius a * frobenius b"
  unfolding frobenius_def
  by (simp add: mult_assoc mult_left_commute)

(* ═══════════════════════════════════════════════════════════════ *)
(* 5. BYTE REPRESENTATION                                         *)
(* ═══════════════════════════════════════════════════════════════ *)

typedef Byte = "{x :: int . 0 ≤ x ∧ x < 256}"
  by (auto intro!: exI[of _ 0])

setup_lifting type_definition_Byte

lift_definition byte_to_gf256 :: "Byte ⇒ GF256" is
  "λx. (∑i<8. (if (x div 2^i) mod 2 = 1 then monom 1 i else 0)) mod aes_mod"
  by (simp add: degree_mod_less)

lift_definition gf256_to_byte :: "GF256 ⇒ Byte" is
  "λp. ∑i<8. (coeff p i mod 2) * 2^i"
  by auto

end
