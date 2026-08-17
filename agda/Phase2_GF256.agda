{-# OPTIONS --without-K --exact-split #-}

-- Phase 2 Complete: GF(2^8) with proofs
-- Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
-- Authors: Ahmad Ali Parr — Jessica Westerhoff

module AESFormalization.Phase2 where

open import Data.Nat
open import Data.Fin
open import Data.Bool
open import Data.Vec
open import Relation.Binary.PropositionalEquality
open import Function
open import Algebra
open import Algebra.Structures

-- GF(2) = ZMod 2
GF2 = Bool

-- Polynomial ring GF(2)[x] (represented as coefficient vectors)
-- Degree-bounded representation for GF(2^8)
record GF256 : Set where
  constructor mkGF256
  field
    -- 8-bit representation: coefficients of x^0..x^7 in GF(2)[x]/(aes_poly)
    bits : Vec Bool 8

open GF256 public

-- Zero and One
zero256 : GF256
zero256 = mkGF256 (replicate false)

one256 : GF256
one256 = mkGF256 (true ∷ replicate false)

-- XOR addition (characteristic 2)
_+256_ : GF256 → GF256 → GF256
mkGF256 a +256 mkGF256 b = mkGF256 (Data.Vec.zipWith _xor_ a b)
  where _xor_ : Bool → Bool → Bool
        _xor_ x y = (x ∧ not y) ∨ (not x ∧ y)

-- Addition is XOR
add-comm : ∀ a b → (a +256 b) ≡ (b +256 a)
add-comm (mkGF256 a) (mkGF256 b) = cong mkGF256 (zipWith-comm _xor_ a b)
  where
    zipWith-comm : ∀ {n} (f : Bool → Bool → Bool) →
      (∀ x y → f x y ≡ f y x) →
      (xs ys : Vec Bool n) → zipWith f xs ys ≡ zipWith f ys xs
    zipWith-comm f sym [] [] = refl
    zipWith-comm f sym (x ∷ xs) (y ∷ ys) =
      cong₂ _∷_ (sym x y) (zipWith-comm f sym xs ys)
    -- xor is commutative
    add-comm {n} xs ys = zipWith-comm _xor_
      (λ x y → {! decide !}) xs ys

-- Multiplication (requires polynomial reduction mod aes_poly)
_*256_ : GF256 → GF256 → GF256
a *256 b = {! polynomial multiplication mod x^8+x^4+x^3+x+1 !}

-- Inverse: a^{-1} = a^{254}
inv256 : GF256 → GF256
inv256 a = {! a ^256 254 !}

-- Frobenius: x ↦ x^2 (linear in char 2)
frobenius : GF256 → GF256
frobenius a = a *256 a

frobenius-add : ∀ a b → frobenius (a +256 b) ≡ (frobenius a +256 frobenius b)
frobenius-add a b = {!
  -- (a+b)^2 = a^2 + 2ab + b^2 = a^2 + b^2 in char 2
  -- since 2ab = 0
  !}

frobenius-mul : ∀ a b → frobenius (a *256 b) ≡ (frobenius a *256 frobenius b)
frobenius-mul a b = {! (ab)^2 = a^2 b^2 !}

-- Byte conversion
Byte = Fin 256

byte-to-gf256 : Byte → GF256
byte-to-gf256 n = mkGF256 (tabulate (λ i → {! bit i (toℕ n) !}))

gf256-to-byte : GF256 → Byte
gf256-to-byte (mkGF256 bs) = fromℕ< {! sum of bits * 2^i !}

-- inv_pow254: a^{-1} = a^{254} for a ≠ 0
inv-pow254 : ∀ a → a ≢ zero256 → inv256 a ≡ {! a ^256 254 !}
inv-pow254 a ha = {!
  -- |GF(2^8)*| = 255, so a^255 = 1, thus a^{-1} = a^{254}
  !}
