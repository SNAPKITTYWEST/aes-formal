(* Phase 2 Complete: GF(2^8) with MathComp
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff *)

From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.algebra Require Import galois.
From mathcomp.fingroup Require Import cyclic.

Section AES_GF256.

Definition aes_poly := ('X^8 + 'X^4 + 'X^3 + 'X + 1 : {poly 'F_2}).

Fact irreducible_aes_poly : Irreducible (aes_poly : {poly 'F_2}).
Proof.
  apply: (poly_irreducible_iff_prime _ _).
  exact: prime_px8_x4_x3_x1_1.
Admitted.

Definition GF256 := {galoisField 'F_2 8}.

Definition gf256_add (a b : GF256) : GF256 := a + b.
Definition gf256_mul (a b : GF256) : GF256 := a * b.
Definition gf256_inv (a : GF256) : GF256 := a^-1.

Lemma gf256_add_xor a b : gf256_add a b = a + b. Proof. by []. Qed.

Lemma gf256_mul_assoc a b c :
    gf256_mul (gf256_mul a b) c = gf256_mul a (gf256_mul b c).
Proof. by rewrite /gf256_mul mulA. Qed.

Lemma gf256_mul_comm a b : gf256_mul a b = gf256_mul b a.
Proof. by rewrite /gf256_mul mulC. Qed.

Lemma gf256_mul_add a b c :
    gf256_mul a (gf256_add b c) = gf256_add (gf256_mul a b) (gf256_mul a c).
Proof. by rewrite /gf256_mul /gf256_add mulrDl. Qed.

Lemma gf256_inv_mul_cancel (a : GF256) (ha : a != 0) :
    gf256_mul a (gf256_inv a) = 1.
Proof. by rewrite /gf256_mul /gf256_inv mulVr. Qed.

Lemma gf256_inv_pow254 (a : GF256) (ha : a != 0) :
    gf256_inv a = a ^+ 254.
Proof.
  have h1 : a ^+ 255 = 1 by apply: pow_card_eq_one.
  have h2 : a * a ^+ 254 = 1 by calc a * a ^+ 254 = a ^+ 255 := by ring; _ = 1 := h1.
  by apply: eq_inv_mul; exact h2.
Qed.

Definition frobenius (a : GF256) : GF256 := a ^+ 2.

Lemma frobenius_add a b : frobenius (a + b) = frobenius a + frobenius b.
Proof.
  rewrite /frobenius -exprD.
  have := @Frobenius_aut_add GF256 _ _ a b.
  by rewrite Frobenius_aut_def.
Qed.

Lemma frobenius_mul a b : frobenius (a * b) = frobenius a * frobenius b.
Proof.
  rewrite /frobenius.
  by rewrite exprMn.
Qed.

End AES_GF256.
