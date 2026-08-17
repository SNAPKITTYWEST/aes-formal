{-# OPTIONS --without-K --exact-split #-}

-- Phase 3 Complete: S-box Polynomial with Full Affine Transform
-- Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
-- Authors: Ahmad Ali Parr — Jessica Westerhoff

module AESFormalization.Phase3 where

open import Data.Nat using (ℕ; zero; suc; _+_; _*_; _≤_)
open import Data.Fin using (Fin; zero; suc; toℕ)
open import Data.Bool using (Bool; true; false; _∧_; _∨_; not)
open import Data.Vec using (Vec; []; _∷_; replicate; zipWith; tabulate; lookup)
open import Data.Vec.Properties
open import Relation.Binary.PropositionalEquality using (_≡_; refl; cong; cong₂; sym; trans)
open import Function using (Bijective; Injective; Surjective; _∘_)
open import Data.Product using (Σ; _,_; proj₁; proj₂; ∃-syntax)

open import AESFormalization.Phase2 using (GF256; zero256; one256; _+256_; _*256_; inv256; bits)

-- ═══════════════════════════════════════════════════════════════
-- 1. AFFINE MATRIX (8×8 over GF(2))
-- ═══════════════════════════════════════════════════════════════

Matrix8x8 : Set
Matrix8x8 = Vec (Vec Bool 8) 8

-- AES S-box affine matrix (circulant structure)
sbox-affine-matrix : Matrix8x8
sbox-affine-matrix =
  (true  ∷ false ∷ false ∷ false ∷ true  ∷ true  ∷ true  ∷ true  ∷ []) ∷
  (true  ∷ true  ∷ false ∷ false ∷ false ∷ true  ∷ true  ∷ true  ∷ []) ∷
  (true  ∷ true  ∷ true  ∷ false ∷ false ∷ false ∷ true  ∷ true  ∷ []) ∷
  (true  ∷ true  ∷ true  ∷ true  ∷ false ∷ false ∷ false ∷ true  ∷ []) ∷
  (true  ∷ true  ∷ true  ∷ true  ∷ true  ∷ false ∷ false ∷ false ∷ []) ∷
  (false ∷ true  ∷ true  ∷ true  ∷ true  ∷ true  ∷ false ∷ false ∷ []) ∷
  (false ∷ false ∷ true  ∷ true  ∷ true  ∷ true  ∷ true  ∷ false ∷ []) ∷
  (false ∷ false ∷ false ∷ true  ∷ true  ∷ true  ∷ true  ∷ true  ∷ []) ∷ []

-- Affine constant: 0x63 = 01100011
sbox-const-vec : Vec Bool 8
sbox-const-vec = true ∷ true ∷ false ∷ false ∷ false ∷ true ∷ true ∷ false ∷ []

-- ═══════════════════════════════════════════════════════════════
-- 2. GF(2) OPERATIONS
-- ═══════════════════════════════════════════════════════════════

_xor_ : Bool → Bool → Bool
false xor y = y
true  xor y = not y

_and_ : Bool → Bool → Bool
false and _ = false
true  and y = y

-- GF(2) dot product of two 8-bit vectors
gf2-dot : Vec Bool 8 → Vec Bool 8 → Bool
gf2-dot [] [] = false
gf2-dot (x ∷ xs) (y ∷ ys) = (x and y) xor (gf2-dot xs ys)

-- Matrix-vector multiplication over GF(2)
mat-vec-mul : Matrix8x8 → Vec Bool 8 → Vec Bool 8
mat-vec-mul m v = tabulate (λ i → gf2-dot (lookup m i) v)

-- Vector XOR
vec-xor : Vec Bool 8 → Vec Bool 8 → Vec Bool 8
vec-xor = zipWith _xor_

-- ═══════════════════════════════════════════════════════════════
-- 3. AFFINE TRANSFORMATION
-- ═══════════════════════════════════════════════════════════════

affine-transform : GF256 → GF256
affine-transform x =
  let input-bits = bits x
      transformed = mat-vec-mul sbox-affine-matrix input-bits
      result = vec-xor transformed sbox-const-vec
  in record { bits = result }

-- ═══════════════════════════════════════════════════════════════
-- 4. S-BOX POLYNOMIAL
-- ═══════════════════════════════════════════════════════════════

sbox-poly : GF256 → GF256
sbox-poly x with bits x
... | bs with bs ≡ replicate false
...   | refl = record { bits = sbox-const-vec }  -- S(0) = 0x63
...   | _    = affine-transform (inv256 x)       -- S(x) = A(x⁻¹)

-- ═══════════════════════════════════════════════════════════════
-- 5. PROPERTIES (stubs — require finite enumeration)
-- ═══════════════════════════════════════════════════════════════

postulate
  sbox-bijective : Bijective sbox-poly
  sbox-no-fixed-points : ∀ (x : GF256) → sbox-poly x ≢ x
  sbox-max-differential : ∀ (Δx Δy : GF256) → Δx ≢ zero256 →
    -- |{x | S(x+Δx) + S(x) = Δy}| ≤ 4
    ℕ  -- placeholder for cardinality bound
  sbox-max-linear-bias : ∀ (a b : Vec Bool 8) →
    -- |Σ (-1)^(a·x + b·S(x))| ≤ 16
    ℕ  -- placeholder for bias bound

-- ═══════════════════════════════════════════════════════════════
-- 6. INVERSE S-BOX
-- ═══════════════════════════════════════════════════════════════

postulate
  inv-affine-transform : GF256 → GF256
  inv-affine-correct : ∀ x → inv-affine-transform (affine-transform x) ≡ x
  affine-inv-correct : ∀ x → affine-transform (inv-affine-transform x) ≡ x

inv-sbox-poly : GF256 → GF256
inv-sbox-poly y with bits y
... | bs with bs ≡ sbox-const-vec
...   | refl = zero256
...   | _    = inv256 (inv-affine-transform y)

postulate
  inv-sbox-correct : ∀ x → inv-sbox-poly (sbox-poly x) ≡ x
  sbox-inv-correct : ∀ x → sbox-poly (inv-sbox-poly x) ≡ x
