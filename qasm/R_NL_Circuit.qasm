// AES R_NL Evaluation — OpenQASM 3.0
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
//
// Grover search for AES-128 key given (P, C) pair.
// Oracle: marks keys where AES_K(P) = C (R_NL = 0)
// Iterations required: ~2^64 (no algebraic speedup — still exponential)

OPENQASM 3.0;
include "stdgates.inc";

qubit[128] key_reg;
qubit[128] plaintext_reg;
qubit[128] ciphertext_reg;
qubit[128] state_reg;
qubit[8]   sbox_ancilla;

// S-box via GF(2^8) inversion (Itoh-Tsujii, ~1000 gates)
// x^254 using addition chain: 254 = 2*127 = 2*(2*63+1) = ...
gate gf256_inv q[8] {
  // Addition chain for x^254 — placeholder
  x q[0];
}

gate sbox_gate q[8] {
  gf256_inv q;
  // XOR with 0x63
  x q[0]; x q[1]; x q[5]; x q[6];
}

gate sbox_layer state[128] {
  for i in [0:15] {
    sbox_gate state[8*i : 8*i+7];
  }
}

gate shift_rows state[128] {
  // Row 1: cyclic left shift 1 byte (8 bits)
  // Row 2: cyclic left shift 2 bytes
  // Row 3: cyclic left shift 3 bytes
  // (SWAP network — omitted for brevity)
}

gate mix_columns state[128] {
  // Circulant matrix [2,3,1,1] over GF(2^8)
  // Each column: 4 GF(2^8) multiplications + additions
}

gate linear_layer state[128] {
  shift_rows state;
  mix_columns state;
}

gate add_round_key state[128], rk[128] {
  for i in [0:127] { cx rk[i], state[i]; }
}

gate round_fn state[128], rk[128] {
  sbox_layer state;
  linear_layer state;
  add_round_key state, rk;
}

// AES-128: 10 rounds
gate aes128 key[128], pt[128] -> ct[128] {
  qubit[128] state;
  reset state;
  // Initial AddRoundKey
  for i in [0:127] { cx pt[i], state[i]; cx key[i], state[i]; }
  // 10 rounds (round keys derived from key schedule — omitted)
  // Final round: no MixColumns
}

// Oracle: phase flip if AES_K(P) = C
gate oracle key[128], pt[128], ct[128] {
  qubit[128] diff;
  reset diff;
  aes128 key, pt;
  // diff = AES(key,pt) XOR ct
  for i in [0:127] { cx ct[i], diff[i]; }
  // Phase flip if diff = 0
  x diff;
  h diff[0];
  mcx diff[1:127], diff[0];
  h diff[0];
  x diff;
}

// Grover diffusion operator
gate diffusion key[128] {
  h key;
  x key;
  h key[0];
  mcx key[1:127], key[0];
  h key[0];
  x key;
  h key;
}

// Main: ~2^64 Grover iterations
reset key_reg;
h key_reg;  // Uniform superposition

// 2^64 iterations (theoretical — not practically executable)
// for i in [0 : 2^64] {
//   oracle key_reg, plaintext_reg, ciphertext_reg;
//   diffusion key_reg;
// }

measure key_reg -> bit[128];
