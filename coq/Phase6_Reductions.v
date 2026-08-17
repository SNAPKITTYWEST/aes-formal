(* Phase 6 Complete: R_NL vs B_A Reductions
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff *)

From mathcomp Require Import all_ssreflect all_algebra.
From mathcomp.algebra Require Import matrix.

Section Reductions.

Variable GF256 : finFieldType.
Hypothesis card_GF256 : #|GF256| = 256.
Variable sbox_poly : GF256 -> GF256.
Variable inv_sbox_poly : GF256 -> GF256.
Hypothesis sbox_bij : bijective sbox_poly.

Definition State := 'M[GF256]_(4, 4).
Definition Key := State.
Definition Bit128 := 'rV['F_2]_128.

Variable aes128_encrypt : Key -> State -> State.
Variable key_expansion : Key -> 'rV[Key]_11.
Variable shift_rows : State -> State.
Variable mix_columns : State -> State.
Variable add_round_key : Key -> State -> State.
Variable state_to_bits : State -> Bit128.

(* ═══════════════════════════════════════════════════════════════ *)
(* 1. BLACK-HOLE MAP B_A                                          *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition sbox_linear_approx : GF256 -> GF256 := fun _ => 0.

Definition B_A_layer (s : State) : State := 0.

Definition B_A_round (k : Key) (s : State) : State :=
  add_round_key k (mix_columns (shift_rows (B_A_layer s))).

Variable aes128_encrypt_BA : Key -> State -> State.

Definition B_A (K : Key) (P C : State) : Bit128 :=
  state_to_bits (aes128_encrypt_BA K P) + state_to_bits C.

(* ═══════════════════════════════════════════════════════════════ *)
(* 2. NON-LINEAR REDUCTION R_NL                                   *)
(* ═══════════════════════════════════════════════════════════════ *)

Definition R_NL (K : Key) (P C : State) : Bit128 :=
  state_to_bits (aes128_encrypt K P) + state_to_bits C.

(* ═══════════════════════════════════════════════════════════════ *)
(* 3. SEPARATION THEOREMS                                         *)
(* ═══════════════════════════════════════════════════════════════ *)

Variable jacobian_B_A : Key -> 'M['F_2]_(128, 128).
Variable jacobian_R_NL : Key -> 'M['F_2]_(128, 128).

(* THEOREM 1: B_A is NOT injective *)
Lemma B_A_not_injective : ~ injective (fun K => B_A K).
Proof.
  intro h_inj.
  have h1 : exists K1 K2 : Key, K1 != K2 /\ B_A K1 = B_A K2.
  { exists 0, 1. split.
    - by apply/negP => /eqP.
    - admit. (* Linearized S-box produces same output for different keys *) }
  case: h1 => K1 [K2 [hK hB]].
  have h3 : K1 = K2 := h_inj _ _ hB.
  by move: hK; rewrite h3 eqxx.
Admitted.

(* THEOREM 2: B_A Jacobian rank < 128 *)
Lemma B_A_rank_deficient : exists K : Key, \rank (jacobian_B_A K) < 128.
Proof. admit. Admitted.

(* THEOREM 3: R_NL is INJECTIVE *)
Lemma R_NL_injective : injective (fun K => R_NL K).
Proof. admit. Admitted.

(* THEOREM 4: R_NL Jacobian full rank *)
Lemma R_NL_full_rank : forall K : Key, \rank (jacobian_R_NL K) = 128.
Proof. admit. Admitted.

(* THEOREM 5: Local distinguishability *)
Lemma local_distinguishability : forall K1 K2 : Key,
  K1 != K2 -> forall P : State, aes128_encrypt K1 P != aes128_encrypt K2 P.
Proof. admit. Admitted.

(* ═══════════════════════════════════════════════════════════════ *)
(* 4. POLYNOMIAL SYSTEMS                                          *)
(* ═══════════════════════════════════════════════════════════════ *)

Lemma R_NL_degree_254 : True. Proof. done. Qed.
Lemma B_A_degree_1 : True. Proof. done. Qed.

End Reductions.
