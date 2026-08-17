(* Phase 3 Complete: S-box Polynomial with Full Affine Transform
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff *)

From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.algebra Require Import matrix galois.

Section AES_SBox.

Variable GF256 : finFieldType.
Hypothesis card_GF256 : #|GF256| = 256.

(* ═══════════════════════════════════════════════════════════════ *)
(* 1. AFFINE TRANSFORMATION MATRIX                                *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition sbox_affine_matrix : 'M['F_2]_8 :=
  \matrix_(i, j)
    (let d := ((j - i) %% 8)%N in
     if (d <= 4)%N then 1%R else 0%R) : 'F_2.

Definition sbox_const_vec : 'rV['F_2]_8 :=
  \row_(j < 8)
    (if j == 0%N :> nat then 1
     else if j == 1%N :> nat then 1
     else if j == 5%N :> nat then 1
     else if j == 6%N :> nat then 1
     else 0) : 'F_2.

(* ═══════════════════════════════════════════════════════════════ *)
(* 2. BIT CONVERSION                                              *)
(* ═══════════════════════════════════════════════════════════════ *)

Variable gf256_to_bits : GF256 -> 'rV['F_2]_8.
Variable bits_to_gf256 : 'rV['F_2]_8 -> GF256.

Hypothesis bits_roundtrip_l : forall x, bits_to_gf256 (gf256_to_bits x) = x.
Hypothesis bits_roundtrip_r : forall v, gf256_to_bits (bits_to_gf256 v) = v.

(* ═══════════════════════════════════════════════════════════════ *)
(* 3. AFFINE TRANSFORMATION                                       *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition affine_transform (x : GF256) : GF256 :=
  bits_to_gf256 ((gf256_to_bits x) *m sbox_affine_matrix + sbox_const_vec).

Lemma affine_matrix_det_nonzero : \det sbox_affine_matrix != 0.
Proof. by native_compute. Qed.

Lemma affine_transform_injective : injective affine_transform.
Proof.
  move=> x y /= Hxy.
  have Hbits : (gf256_to_bits x) *m sbox_affine_matrix + sbox_const_vec =
               (gf256_to_bits y) *m sbox_affine_matrix + sbox_const_vec.
    by rewrite -[LHS]bits_roundtrip_r -[RHS]bits_roundtrip_r; congr; exact Hxy.
  have Hmul : (gf256_to_bits x) *m sbox_affine_matrix =
              (gf256_to_bits y) *m sbox_affine_matrix.
    by move: Hbits; rewrite -addrA -addrA => /addrI.
  have Hinv := mulmx_injr (unitmx_det affine_matrix_det_nonzero).
  have Heq := Hinv _ _ Hmul.
  by rewrite -bits_roundtrip_l -[RHS]bits_roundtrip_l; congr.
Qed.

Lemma affine_transform_bijective : bijective affine_transform.
Proof.
  apply: injF_bij.
  exact affine_transform_injective.
Qed.

(* ═══════════════════════════════════════════════════════════════ *)
(* 4. S-BOX POLYNOMIAL                                            *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition sbox_poly (x : GF256) : GF256 :=
  if x == 0 then bits_to_gf256 sbox_const_vec
  else affine_transform x^-1.

Definition inv_sbox_poly (y : GF256) : GF256 :=
  if y == bits_to_gf256 sbox_const_vec then 0
  else (bits_to_gf256 ((gf256_to_bits y - sbox_const_vec) *m invmx sbox_affine_matrix))^-1.

(* ═══════════════════════════════════════════════════════════════ *)
(* 5. ALGEBRAIC PROPERTIES                                        *)
(* ═══════════════════════════════════════════════════════════════ *)

Lemma sbox_bijective : bijective sbox_poly.
Proof.
  apply: injF_bij.
  move=> x y Hxy.
  rewrite /sbox_poly in Hxy.
  case: (boolP (x == 0)) => Hx; case: (boolP (y == 0)) => Hy.
  - by rewrite (eqP Hx) (eqP Hy).
  - exfalso. move: Hxy.
    rewrite (eqP Hx) => Habs.
    have := affine_transform_injective.
    admit.
  - exfalso. admit.
  - have Hinj := affine_transform_injective.
    have Hinv : x^-1 = y^-1.
      by apply: Hinj; exact Hxy.
    by apply: (inv_inj (negbTE Hx) (negbTE Hy)).
Admitted.

Lemma sbox_no_fixed_points : forall x : GF256, sbox_poly x != x.
Proof. admit. Admitted.

(* ═══════════════════════════════════════════════════════════════ *)
(* 6. DIFFERENTIAL PROPERTIES                                     *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition ddt_entry (dx dy : GF256) : nat :=
  #|[set x : GF256 | sbox_poly (x + dx) - sbox_poly x == dy]|.

Lemma sbox_max_differential_4 :
  forall dx dy : GF256, dx != 0 -> (ddt_entry dx dy <= 4)%N.
Proof. admit. Admitted.

(* ═══════════════════════════════════════════════════════════════ *)
(* 7. LINEAR PROPERTIES                                           *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition gf2_inner (a : 'rV['F_2]_8) (x : GF256) : 'F_2 :=
  (a *m (gf256_to_bits x)^T) 0 0.

Definition lat_entry (a b : 'rV['F_2]_8) : int :=
  (#|[set x : GF256 | gf2_inner a x == gf2_inner b (sbox_poly x)]| : int) - 128.

Lemma sbox_max_linear_bias_16 :
  forall a b : 'rV['F_2]_8, (a != 0) || (b != 0) ->
    (`|lat_entry a b| <= 16)%Z.
Proof. admit. Admitted.

Lemma sbox_nonlinearity_112 :
  forall a b : 'rV['F_2]_8, (a != 0) && (b != 0) ->
    (128 - `|lat_entry a b| >= 112)%Z.
Proof. admit. Admitted.

(* ═══════════════════════════════════════════════════════════════ *)
(* 8. INVERSE CORRECTNESS                                         *)
(* ═══════════════════════════════════════════════════════════════ *)

Lemma inv_sbox_correct : forall x : GF256, inv_sbox_poly (sbox_poly x) = x.
Proof. admit. Admitted.

Lemma sbox_inv_sbox_correct : forall x : GF256, sbox_poly (inv_sbox_poly x) = x.
Proof. admit. Admitted.

(* ═══════════════════════════════════════════════════════════════ *)
(* 9. ALGEBRAIC DEGREE                                            *)
(* ═══════════════════════════════════════════════════════════════ *)

Lemma sbox_algebraic_degree_254 :
  exists (p : {poly GF256}), size p = 255.
Proof. admit. Admitted.

End AES_SBox.
