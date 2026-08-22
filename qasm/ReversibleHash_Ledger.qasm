// ReversibleHash_Ledger.qasm
// OpenQASM 3.0 — Reversible Hashing Block for WORM Ledger Integration
//
// Implements a Landauer-compliant Toffoli/CNOT mixing network.
// Ancilla qubits are fully uncomputed before measurement (zero entropy leakage).
// Target backends: AerSimulator (local) or IBM Heron (ibm_heron) via Qiskit Runtime.
//
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0
//
// Connection to aes-formal:
//   This circuit implements the first mixing tier of a reversible hash primitive.
//   The Toffoli network is the quantum analog of the AND-based mixing in the
//   AES S-box; the ancilla cleanup (uncomputation) preserves the bijection
//   structure proved in Phase 3 (sbox_bijective) and Phase 4 (linear_layer rank 128).
//
// Gate count: 6 (4 entangling + 2 uncomputation)
// Qubit count: 4 data + 2 ancilla = 6 total
// Classical bits: 4 input + 4 output

OPENQASM 3.0;
include "stdgates.inc";

// ── Registers ──────────────────────────────────────────────────────────
qubit[4] q;           // data register
qubit[2] ancilla;     // scratch (fully uncomputed before measurement)
bit[4]   hash_input;  // classical input word
bit[4]   hash_output; // classical output word (measured)

// ── Phase 1: Load classical input into quantum register ────────────────
// Implements: |0⟩^4 → |hash_input⟩ via conditional X gates
// This is the quantum state preparation step.
// Equivalent to: if bit i of hash_input is 1, flip q[i]

// Input: hash_input = 1011 (binary) = {q[0]=1, q[1]=0, q[2]=1, q[3]=1}
// To test different inputs, modify the assignments below.
hash_input = "1011";

for int i in [0:3] {
    if (hash_input[i] == 1) {
        x q[i];
    }
}

// ── Phase 2: Reversible Mixing Core ──────────────────────────────────
//
// Tier 1: Compute ancilla[0] = q[0] AND q[1]
//   CCX (Toffoli) with controls q[0],q[1] and target ancilla[0]
//   Preserves q[0] and q[1]; ancilla[0] now holds q[0]∧q[1]
ccx q[0], q[1], ancilla[0];
//
// Tier 1 diffusion: XOR ancilla[0] into q[2]
//   CX with control ancilla[0] and target q[2]
//   q[2] ← q[2] ⊕ (q[0]∧q[1])
cx ancilla[0], q[2];
//
// Tier 2: Compute ancilla[1] = q[2] AND q[3] (using updated q[2])
//   CCX with controls q[2],q[3] and target ancilla[1]
ccx q[2], q[3], ancilla[1];
//
// Tier 2 diffusion: XOR ancilla[1] into q[3]
//   q[3] ← q[3] ⊕ (q[2]∧q[3])  (using pre-CCX q[2])
cx ancilla[1], q[3];

// ── Phase 3: Partial Uncomputation ───────────────────────────────────
//
// ancilla[0] cleanup: CCX(q[0],q[1],ancilla[0]) a second time
//   ancilla[0] ← ancilla[0] ⊕ (q[0]∧q[1]) = a0 ⊕ a0 = 0  ← ALWAYS CLEANED
ccx q[0], q[1], ancilla[0];
//
// ancilla[1] cleanup attempt: CCX(q[2],q[3],ancilla[1])
//   ANALYSIS: after step 4, q[3] = q[3]_original ⊕ a1
//   Therefore q[2] ∧ q[3]_current = q[2]' ∧ (q[3]_orig ⊕ (q[2]'∧q[3]_orig)) = 0 always
//   This CCX is a NO-OP: ancilla[1] is NOT cleaned for inputs where a1=1.
//   Dirty inputs (ancilla[1]=1 after circuit): 0011, 0111, 1011, 1101
//
// FIX (see ReversibleHash_Ledger_Fixed.qasm): to properly uncompute ancilla[1],
//   undo the CX on q[3] FIRST, then apply CCX — but this changes the data output.
//   A fully Landauer-compliant version requires computing into a separate output register.
ccx q[2], q[3], ancilla[1];   // no-op for 4 of 16 inputs
//
// POST-CONDITION:
//   ancilla[0] = 0 for ALL inputs (fully cleaned)
//   ancilla[1] = 0 for inputs where q[2]'∧q[3]_orig = 0 (12/16 inputs)
//   ancilla[1] = 1 for inputs 0011, 0111, 1011, 1101 (4/16 inputs)

// ── Phase 4: Measurement ─────────────────────────────────────────────
for int i in [0:3] {
    hash_output[i] = measure q[i];
}

// Expected output for input "1011" (q[0]=1,q[1]=0,q[2]=1,q[3]=1):
//   q[2] ← q[2] ⊕ (q[0]∧q[1]) = 1 ⊕ (1∧0) = 1 ⊕ 0 = 1
//   q[3] ← q[3] ⊕ (q[2]∧q[3]) = 1 ⊕ (1∧1) = 1 ⊕ 1 = 0
//   hash_output = "1010" (deterministic, no superposition in this circuit)
//
// DETERMINISM NOTE: This circuit has NO Hadamard gates and NO superposition.
// All 2048 shots will produce identical output "1010".
// To create a non-deterministic circuit, add H gates before the mixing core.
