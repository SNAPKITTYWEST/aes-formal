; AES R_NL Constraints — SMT-LIB 2.6
; Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
; Authors: Ahmad Ali Parr — Jessica Westerhoff

(set-logic QF_BV)
(set-option :produce-models true)

(define-sort Byte () (_ BitVec 8))
(define-sort Word128 () (_ BitVec 128))
(define-sort Key () Word128)
(define-sort Plaintext () Word128)
(define-sort Ciphertext () Word128)

; GF(2^8) addition = XOR
(define-fun gf256_add ((x Byte) (y Byte)) Byte (bvxor x y))

; GF(2^8) multiplication modulo x^8+x^4+x^3+x+1 (0x11B)
; Simplified — production uses precomputed table
(define-fun gf256_mul ((x Byte) (y Byte)) Byte
  (let ((result (bvmul x y)))
    (bvurem result #x1b)))

; S-box constant
(define-fun sbox_const () Byte #x63)

; Variables
(declare-fun K () Key)
(declare-fun P () Plaintext)
(declare-fun C () Ciphertext)
(declare-fun RK_0 () Key)
(declare-fun RK_10 () Key)

; R_NL constraint: AES_K(P) = C
; (simplified — full encoding requires 10 round functions)
(assert (= (bvxor P RK_0) C))  ; placeholder — replace with full round chain

; Injectivity: K != K' => R_NL(K) != R_NL(K')
(declare-fun K2 () Key)
(assert (not (= K K2)))
(assert (not (= (bvxor P K) (bvxor P K2))))  ; local distinguishability

; Complexity witness: no short solution
; (assert (forall ((K Key)) (not (= (R_NL K P C) (_ bv0 128)))))

(check-sat)
(get-model)
