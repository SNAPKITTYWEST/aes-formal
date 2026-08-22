// ReversibleHash_Ledger_Fixed.qasm
// OpenQASM 3.0 — Corrected reversible hash block with full ancilla cleanup.
//
// Fixes the uncomputation bug in ReversibleHash_Ledger.qasm:
// In the original, step 5 (CCX to uncompute ancilla[1]) was a no-op because
// q[3] had already been modified by step 4 (CX ancilla[1] → q[3]).
//
// Correct uncomputation order is the EXACT REVERSE of the forward circuit:
//   Forward:  CCX(q0,q1,a0), CX(a0,q2), CCX(q2,q3,a1), CX(a1,q3)
//   Reverse:  CX(a1,q3), CCX(q2,q3,a1), CX(a0,q2), CCX(q0,q1,a0)
//
// TRADE-OFF: Full uncomputation restores q to the original input state.
// The "hash output" is therefore the SAME as the input. To retain a useful
// mixed output, use the compute-copy-uncompute pattern (separate output register):
//   1. Compute mixed state into ancilla:  |q⟩|0⟩ → |q⟩|f(q)⟩
//   2. Swap output to fresh register:     |q⟩|f(q)⟩ → |f(q)⟩|q⟩
//   3. Uncompute using restored register: |f(q)⟩|q⟩ → |f(q)⟩|0⟩
//
// For this simple circuit, we demonstrate option B: measure ancilla BEFORE
// uncomputing, capturing the mixed state as the hash output.
//
// Copyright (C) 2026 Bel Esprit D'Accord Irrevocable Trust
// Authors: Ahmad Ali Parr — Jessica Westerhoff
// License: BSL-1.1 / AGPL-3.0 / MPL-2.0

OPENQASM 3.0;
include "stdgates.inc";

qubit[4] q;
qubit[2] ancilla;
bit[4]   hash_input;
bit[4]   hash_output;
bit[2]   ancilla_check;   // verify ancilla = |00⟩ after uncomputation

hash_input = "1011";

// ── Phase 1: Load ─────────────────────────────────────────────────────
for int i in [0:3] {
    if (hash_input[i] == 1) {
        x q[i];
    }
}

// ── Phase 2: Forward mixing ────────────────────────────────────────────
ccx q[0], q[1], ancilla[0];   // a0 = q0 & q1
cx ancilla[0], q[2];           // q2 ^= a0
ccx q[2], q[3], ancilla[1];   // a1 = q2' & q3
cx ancilla[1], q[3];           // q3 ^= a1

// ── Phase 3: Measure output BEFORE uncomputation ──────────────────────
// Capturing the mixed state as the hash output.
// State at this point: q = mixed, ancilla = [a0, a1]
for int i in [0:3] {
    hash_output[i] = measure q[i];
}

// ── Phase 4: Full uncomputation (correct reverse order) ───────────────
// Reverse step 4:  CX(a1, q3) again to restore q3
cx ancilla[1], q[3];
// Reverse step 3:  CCX with RESTORED q3 — now a1 is correctly uncomputed
ccx q[2], q[3], ancilla[1];   // a1 back to |0⟩ ✓
// Reverse step 2:  CX(a0, q2) again to restore q2
cx ancilla[0], q[2];
// Reverse step 1:  CCX to restore a0
ccx q[0], q[1], ancilla[0];   // a0 back to |0⟩ ✓

// ── Phase 5: Verify ancilla = |00⟩ ───────────────────────────────────
ancilla_check[0] = measure ancilla[0];
ancilla_check[1] = measure ancilla[1];
// Expected: ancilla_check = "00" for ALL 16 inputs

// Expected output for input "1011":
//   Same as original circuit: hash_output = "1010"
//   ancilla_check = "00" (now ALWAYS clean)
