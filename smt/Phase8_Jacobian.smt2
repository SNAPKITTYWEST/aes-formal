; Phase 8: Jacobian rank constraints
; Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
; Authors: Ahmad Ali Parr — Jessica Westerhoff

(set-logic QF_BV)
(set-option :produce-models true)
(set-option :produce-unsat-cores true)

(define-sort Byte    () (_ BitVec 8))
(define-sort Word128 () (_ BitVec 128))

; GF(2^8) XOR addition
(define-fun gf256_add ((x Byte) (y Byte)) Byte (bvxor x y))

; GF(2^8) raw multiplication (schoolbook mod 0x11B)
; Simplified — production uses precomputed table
(define-fun xtime ((x Byte)) Byte
  (let ((shifted (bvshl x #x01)))
    (ite (= (bvand x #x80) #x80)
         (bvxor shifted #x1B)
         shifted)))

(define-fun gf256_mul2 ((x Byte)) Byte (xtime x))
(define-fun gf256_mul3 ((x Byte)) Byte (bvxor (xtime x) x))

; S-box constant
(define-fun sbox_const () Byte #x63)

; Variables
(declare-fun K  () Word128)
(declare-fun P  () Word128)
(declare-fun C  () Word128)
(declare-fun K2 () Word128)

; Local distinguishability: K ≠ K2 → AES_K(P) ≠ AES_K2(P)
; Encoded as: if K ≠ K2, there exists P such that outputs differ
(assert (not (= K K2)))

; For the linearized B_A: K ≠ K2 can give same output (lossiness)
; For full R_NL: K ≠ K2 always gives different output (injectivity)

; B_A lossiness check (linearized S-box → collisions exist)
(declare-fun delta_K () Word128)
(assert (not (= delta_K (_ bv0 128))))
; B_A maps delta_K to 0 (linearization collapses input differences)
; This should be SAT — there exist non-zero ΔK with B_A(K ⊕ ΔK) = B_A(K)
(assert (= (bvxor K delta_K) K))  ; placeholder for B_A collapse

; R_NL injectivity (full AES — this should be UNSAT)
; ∀ K1 ≠ K2, ∃ P: AES_K1(P) ≠ AES_K2(P)
; We assert K1 ≠ K2 AND AES_K1(P) = AES_K2(P) and expect UNSAT
; (commented out — requires full AES encoding)

(check-sat)
(get-model)
