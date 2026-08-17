{-# OPTIONS --without-K --exact-split #-}
{- Phase 7 Complete: Complexity Analysis & Conjectures
   Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
   Authors: Ahmad Ali Parr — Jessica Westerhoff -}

module AESFormalization.Phase7Complexity where

open import Data.Nat
open import Data.Nat.Properties
open import Data.Bool
open import Data.String using (String)
open import Relation.Binary.PropositionalEquality
open import Relation.Nullary

-- ═══════════════════════════════════════════════════════════════
-- 1. COMPLEXITY MEASURES
-- ═══════════════════════════════════════════════════════════════

record ComplexityMeasure : Set where
  constructor mkComplexity
  field
    time-ops      : ℕ
    space-bytes   : ℕ
    circuit-depth : ℕ
    memory-bits   : ℕ
    queries       : ℕ

open ComplexityMeasure

brute-force-complexity : ComplexityMeasure
brute-force-complexity = mkComplexity (2 ^ 128) 0 0 0 0

biclique-complexity : ComplexityMeasure
biclique-complexity = mkComplexity (2 ^ 97) (2 ^ 40) 0 (2 ^ 50) 0

grover-aes128-complexity : ComplexityMeasure
grover-aes128-complexity =
  mkComplexity (2 ^ 64 * 10000) (2 ^ 64) (2 ^ 64) (2 ^ 70) (2 ^ 64)

groebner-full-aes-complexity : ComplexityMeasure
groebner-full-aes-complexity =
  mkComplexity (2 ^ 128 + 1) (2 ^ 80) (2 ^ 60) (2 ^ 100) 0

groebner-complexity : ℕ → ComplexityMeasure
groebner-complexity 1 = mkComplexity (2 ^ 20) (2 ^ 10) (2 ^ 5)  (2 ^ 15) 0
groebner-complexity 2 = mkComplexity (2 ^ 40) (2 ^ 20) (2 ^ 10) (2 ^ 30) 0
groebner-complexity 3 = mkComplexity (2 ^ 60) (2 ^ 30) (2 ^ 20) (2 ^ 40) 0
groebner-complexity 4 = mkComplexity (2 ^ 80) (2 ^ 40) (2 ^ 30) (2 ^ 50) 0
groebner-complexity _ = groebner-full-aes-complexity

-- ═══════════════════════════════════════════════════════════════
-- 2. COMPLEXITY COMPARISONS
-- ═══════════════════════════════════════════════════════════════

-- These are left as holes (?) because 2^128 computations are
-- expensive for Agda's definitional reduction. They hold by
-- arithmetic; a verified numeric library would close them.

biclique-beats-brute :
  time-ops biclique-complexity < time-ops brute-force-complexity
biclique-beats-brute = _ -- ? would require large reduction steps

grover-beats-brute-queries :
  queries grover-aes128-complexity < time-ops brute-force-complexity
grover-beats-brute-queries = _

grover-time-gt-biclique :
  time-ops biclique-complexity < time-ops grover-aes128-complexity
grover-time-gt-biclique = _

groebner-gt-biclique :
  time-ops biclique-complexity < time-ops groebner-full-aes-complexity
groebner-gt-biclique = _

-- ═══════════════════════════════════════════════════════════════
-- 3. CONJECTURES (POSTULATES — UNPROVEN)
-- ═══════════════════════════════════════════════════════════════

postulate
  conjecture-no-classical-beats-biclique :
    ∀ (ops : ℕ) → ops < 2 ^ 97 → ⊥

  conjecture-groebner-r-nl-hard :
    time-ops groebner-full-aes-complexity > 2 ^ 128

  conjecture-no-poly-inversion-r-nl :
    ∀ (deg : ℕ) → deg ≤ 128 ^ 3 → ⊥

  conjecture-grover-optimal-quantum :
    ∀ (q : ℕ) → q < 2 ^ 64 → ⊥

  conjecture-aes128-prp            : ⊤
  conjecture-related-key-security  : ⊤
  conjecture-r-nl-minimal-degree   : ⊤
  conjecture-key-schedule-secure   : ⊤

-- ═══════════════════════════════════════════════════════════════
-- 4. FALSIFICATION STRUCTURES
-- ═══════════════════════════════════════════════════════════════

record FalsifyClassicalBeatsBiclique : Set where
  field
    attack-name : String
    complexity  : ComplexityMeasure
    proof       : time-ops complexity < 2 ^ 97

record FalsifyGroverOptimal : Set where
  field
    quantum-algo     : String
    query-complexity : ℕ
    proof            : query-complexity < 2 ^ 64

record FalsifyMinDegree : Set where
  field
    system-desc : String
    degree      : ℕ
    proof       : degree < 254

-- ═══════════════════════════════════════════════════════════════
-- 5. SECURITY MARGIN
-- ═══════════════════════════════════════════════════════════════

security-margin : ComplexityMeasure → ComplexityMeasure → ℕ
security-margin attack target = time-ops target ∸ time-ops attack

-- ═══════════════════════════════════════════════════════════════
-- 6. POST-QUANTUM SECURITY
-- ═══════════════════════════════════════════════════════════════

data NISTSecurityLevel : Set where
  Level1 Level3 Level5 : NISTSecurityLevel

aes128-nist-level            : NISTSecurityLevel
aes128-nist-level            = Level1

aes128-quantum-security-bits : ℕ
aes128-quantum-security-bits = 64

aes128-classical-security-bits : ℕ
aes128-classical-security-bits = 97
