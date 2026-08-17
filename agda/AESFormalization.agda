{-# OPTIONS --without-K --exact-split #-}

-- AES Algebraic Cryptanalysis — Agda Core
-- Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
-- Authors: Ahmad Ali Parr — Jessica Westerhoff

module AESFormalization.AgdaCore where

open import Data.Nat
open import Data.Fin
open import Data.Bool
open import Data.Vec
open import Relation.Binary.PropositionalEquality
open import Function

Bit = Bool
Byte = Fin 256
Word128 = Vec Byte 16
Key = Word128
Plaintext = Word128
Ciphertext = Word128
Round = Fin 11

record GF256 : Set where
  field val : Fin 256
open GF256 public

sbox-poly : GF256 → GF256
sbox-poly x with x .val ≡ 0
... | yes _ = record { val = fromℕ 0x63 }
... | no _  = {!!} -- x⁻¹ + 0x63 in GF(2^8)

State = Vec (Vec Byte 4) 4

shift-rows : State → State
shift-rows s = tabulate λ i → tabulate λ j → lookup (lookup s i) (inject≤ ((toℕ j + toℕ i) mod 4) _)

mix-columns : State → State
mix-columns s = {!!}

linear-layer : State → State
linear-layer = mix-columns ∘ shift-rows

-- Black-hole map (lossy linearization)
Bₐ : Key → Plaintext → Ciphertext → Vec Bool 128
Bₐ = {!!}

-- Non-linear reduction (preserves S-box polynomial)
Rₙₗ : Key → Plaintext → Ciphertext → Vec Bool 128
Rₙₗ = {!!}

-- Jacobian full rank
JacobianFullRank : (K : Key) → Set
JacobianFullRank K = {!!} -- rank(jacobian(F_K)) = 128

-- Injectivity of Rₙₗ
RₙₗInjective : (K K' : Key) → K ≢ K' →
  Σ[ P ∈ Plaintext ] Rₙₗ K P {!!} ≢ Rₙₗ K' P {!!}
RₙₗInjective = {!!}

-- Local distinguishability
LocalDist : (K K' : Key) → K ≢ K' → (P : Plaintext) → {!!} ≢ {!!}
LocalDist = {!!}

-- B_A lossy
BₐLossy : Σ[ K ∈ Key ] {!!} -- rank(jacobian(B_A(K))) < 128
BₐLossy = {!!}

-- No verified attack
NoVerifiedAttack : ¬ Σ[ A ∈ (Key → Ciphertext → Plaintext → Key) ] {!!}
NoVerifiedAttack = {!!}

-- Complexity
record Complexity : Set where
  field time space depth memory : ℕ

GroebnerCost : (K : Key) → Complexity
GroebnerCost K = {!!} -- > 2¹²⁸

BicliqueCost : Complexity
BicliqueCost = record { time = 2 ^ 97 ; space = 0 ; depth = 0 ; memory = 0 }
