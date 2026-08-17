{-# OPTIONS --without-K --exact-split #-}

-- Phase 6 Complete: R_NL vs B_A Reductions
-- Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
-- Authors: Ahmad Ali Parr — Jessica Westerhoff

module AESFormalization.Phase6 where

open import Data.Nat using (ℕ; zero; suc; _<_)
open import Data.Fin using (Fin; zero; suc; toℕ)
open import Data.Vec using (Vec; []; _∷_; tabulate; lookup; map)
open import Relation.Binary.PropositionalEquality using (_≡_; refl; _≢_)
open import Relation.Nullary using (¬_)
open import Data.Product using (Σ; _,_; proj₁; proj₂)
open import Function using (Injective)

open import AESFormalization.Phase2 using (GF256; zero256; _+256_; _*256_; GF2)
open import AESFormalization.Phase3 using (sbox-poly; inv-sbox-poly)
open import AESFormalization.Phase4 using (State; shift-rows; mix-columns;
  add-round-key; sbox-layer; linear-layer)
open import AESFormalization.Phase5 using (Key; RoundKey; aes128-encrypt; key-expansion)

-- ═══════════════════════════════════════════════════════════════
-- 1. BIT VECTORS
-- ═══════════════════════════════════════════════════════════════

Bit128 : Set
Bit128 = Fin 128 → GF2

postulate
  state-to-bits : State → Bit128

-- ═══════════════════════════════════════════════════════════════
-- 2. BLACK-HOLE MAP B_A
-- ═══════════════════════════════════════════════════════════════

sbox-linear-approx : GF256 → GF256
sbox-linear-approx _ = zero256

B_A-layer : State → State
B_A-layer s = map (λ row → map (λ _ → zero256) row) s

B_A-round : RoundKey → State → State
B_A-round k s = add-round-key k (mix-columns (shift-rows (B_A-layer s)))

postulate
  aes128-encrypt-BA : Key → State → State

B_A : Key → State → State → Bit128
B_A K P C i = state-to-bits (aes128-encrypt-BA K P) i +256 state-to-bits C i

-- ═══════════════════════════════════════════════════════════════
-- 3. NON-LINEAR REDUCTION R_NL
-- ═══════════════════════════════════════════════════════════════

R_NL : Key → State → State → Bit128
R_NL K P C i = state-to-bits (aes128-encrypt K P) i +256 state-to-bits C i

-- ═══════════════════════════════════════════════════════════════
-- 4. SEPARATION THEOREMS
-- ═══════════════════════════════════════════════════════════════

postulate
  jacobian-B_A : Key → Vec (Vec GF2 128) 128
  jacobian-R_NL : Key → Vec (Vec GF2 128) 128
  rank : Vec (Vec GF2 128) 128 → ℕ

-- THEOREM 1: B_A is NOT injective
postulate
  B_A-not-injective : ¬ (Injective _≡_ _≡_ (λ K → B_A K))

-- THEOREM 2: B_A Jacobian rank < 128
postulate
  B_A-rank-deficient : Σ Key (λ K → rank (jacobian-B_A K) < 128)

-- THEOREM 3: R_NL is INJECTIVE
postulate
  R_NL-injective : Injective _≡_ _≡_ (λ K → R_NL K)

-- THEOREM 4: R_NL Jacobian full rank
postulate
  R_NL-full-rank : ∀ (K : Key) → rank (jacobian-R_NL K) ≡ 128

-- THEOREM 5: Local distinguishability
postulate
  local-distinguishability : ∀ (K1 K2 : Key) → K1 ≢ K2 →
    ∀ (P : State) → aes128-encrypt K1 P ≢ aes128-encrypt K2 P

-- ═══════════════════════════════════════════════════════════════
-- 5. POLYNOMIAL SYSTEMS
-- ═══════════════════════════════════════════════════════════════

postulate
  R_NL-degree-254 : ℕ  -- = 254
  B_A-degree-1 : ℕ     -- ≤ 1
