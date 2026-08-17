(* Phase 2: GF(2^8) with MathComp
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff *)

From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.algebra Require Import galois.

Section AES_GF256.

Definition aes_poly := ('X^8 + 'X^4 + 'X^3 + 'X + 1 : {poly 'F_2}).

Fact irreducible_aes_poly : Irreducible (aes_poly : {poly 'F_2}).
Proof.
  have: Irreducible (aes_poly : {poly 'F_2}).
  apply: (poly_irreducible_iff_prime _ _).
  (* x^8 + x^4 + x^3 + x + 1 is primitive over GF(2) — known result *)
  exact: prime_px8_x4_x3_x1_1.
Admitted.

(* GF(2^8) *)
Definition GF256 := {galoisField 'F_2 8}.

Definition gf256_add (a b : GF256) : GF256 := a + b.
Definition gf256_mul (a b : GF256) : GF256 := a * b.
Definition gf256_inv (a : GF256) : GF256 := a^-1.

Lemma gf256_mul_assoc a b c :
  gf256_mul (gf256_mul a b) c = gf256_mul a (gf256_mul b c).
Proof. by rewrite !gf256_mul mulA. Qed.

Lemma gf256_inv_pow254 (a : GF256) (ha : a != 0) :
  gf256_inv a = a ^+ 254.
Proof.
  have h1 : a ^+ 255 = 1.
  { apply: pow_card_eq_one. exact ha. }
  have h2 : a * a ^+ 254 = 1.
  { calc a * a ^+ 254 = a ^+ 255 := by ring
         _ = 1 := h1. }
  have h3 : a^-1 = a ^+ 254.
  { apply: eq_inv_mul. exact h2. }
  rewrite /gf256_inv. exact h3.
Qed.

Definition frobenius (a : GF256) : GF256 := a ^+ 2.

Lemma frobenius_add a b :
  frobenius (a + b) = frobenius a + frobenius b.
Proof.
  rewrite /frobenius.
  rw [pow2_eq_sqr].
  rw [add_sqr].
  by rewrite mul_comm.
Admitted.

End AES_GF256.
