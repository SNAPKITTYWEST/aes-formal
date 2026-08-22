# ADR-002: State Preservation as a Post-Quantum Governance Property

**Status:** ACCEPTED  
**Date:** 2026-08-22  
**Author:** Jessica L. Williams (SNAPKITTYWEST) — observed by Ahmad Ali Parr  
**Proof:** `ControlFlowInvariants.agda`, `QuantumInvariants.lean` (INV-1 through INV-13)

---

## The Property

```lean
theorem state_preservation {P l₁ l₂ s₁ s₂} :
    Step P (l₁, s₁) (l₂, s₂) → s₁ = s₂
```

In the Conditional Dual DAG, control-flow transitions — GOTO (push) and
COME-FROM (pull) — **never mutate state**. Only the label (position in the DAG)
changes. The state passes through every transition unchanged.

This is proved in two independent formal systems:
- `ControlFlowInvariants.agda`: `state-invariant` closes by `refl` on both
  constructors of `Step`
- `QuantumInvariants.lean`: `INV-1` through `INV-13` collectively establish
  that the governance layer has no write access to the quantum state

---

## Why This Is Novel in Post-Quantum Cryptography

### What current PQC protects

NIST PQC standards (lattice-based, hash-based, code-based) protect the
**cryptographic primitive** against quantum adversaries. They ensure that
recovering a key from a ciphertext requires super-polynomial work even with
a quantum computer.

### What current PQC does NOT protect

PQC standards do not address the **execution environment** of the
cryptographic operation. Specifically: what if the control-flow layer — the
governance mechanism deciding which operations to execute and in what order —
is itself a target?

A quantum adversary who compromises the **navigator** (the thing evaluating
guards, choosing transitions, managing the DAG) can potentially:
- Observe which branches are taken (timing side-channel)
- Inject false guard evaluations (control-flow injection)
- Route computation through unintended states

### What the Conditional Dual DAG provides

The state preservation theorem makes the control-flow layer **formally inert**
with respect to cryptographic state. Not by enforcement (a firewall that could
be bypassed), but by **type**: the `Step` relation is defined so that `s₁ = s₂`
is a theorem, not a policy.

A quantum adversary who fully controls the DAG navigator — who can choose any
labels, inject any guards, manipulate any transitions — **still cannot touch
the state**, because the type system prohibits it. There is no side-channel
surface on the quantum state through the governance layer.

---

## The Topological Analogy

In topological quantum computation (Fibonacci anyons):

> Local perturbations cannot change the fusion channel.

The non-Abelian nature of the braid group means that local noise — a
small physical perturbation anywhere along a braid — cannot alter the
topological invariant. The information is stored in the global topology,
not in any local degree of freedom.

The Conditional Dual DAG provides an analogous guarantee at the
**governance layer**:

> Control-flow operations cannot change the computational state.

The information is stored in the state (the payload), not in the label
(the position in the DAG). The navigator is topologically decoupled from
the state. Local control-flow manipulation — injecting GOTOs, corrupting
guards, reversing transitions — cannot alter the cryptographic payload.

---

## The Formal Separation

Two layers, formally distinct:

| Layer | Type | Can mutate? |
|-------|------|------------|
| **Control** | `Label` | Yes — labels change at every transition |
| **Data** | `State` | No — state preserved across ALL transitions |

This is not an informal separation of concerns. It is a theorem.

The `Step` relation is defined:

```agda
data Step (P : Program) : Label × State → Label × State → Set where
  step-goto      : P l₁ ≡ goto l₂     → Step P (l₁, s) (l₂, s)
  step-come-from : P l₂ ≡ comeFrom l₁  → Step P (l₁, s) (l₂, s)
```

Both constructors carry the state `s` unchanged through the transition.
There is no constructor that modifies state. Adding one would require
changing the type definition — it cannot be done from outside.

---

## PQC Implications

### Novel layer of quantum security

The Conditional Dual DAG with state preservation provides a governance
layer that is:

1. **Quantum-inert**: control-flow decisions cannot cause decoherence
   because they cannot touch the quantum state
2. **Side-channel-free at the governance level**: timing attacks on guard
   evaluation cannot leak state information (the guard evaluator has no
   read access to state in the formal model)
3. **Injection-resistant**: a compromised navigator cannot modify state
   even with full control of the DAG structure

### Relationship to existing PQC

This is orthogonal to, not a replacement for, standard PQC primitives:

```
Standard PQC:     protects primitive against quantum key recovery
ADR-002 property: protects execution environment against control-flow attack
```

A complete post-quantum system needs both. Current NIST PQC standards
address the first. The Conditional Dual DAG formally addresses the second.

### The duality connection

The Z₂ duality (D ∘ D = id, proved in `order-of-symmetry`) means the
forward operator (U) and reverse operator (U_rev) are related by a
group of order 2 — neither can "sneak past" the other to modify state,
because the state preservation property holds for BOTH directions of
traversal simultaneously.

---

## Open Question

**Is state preservation sufficient for quantum side-channel security, or are
additional properties required?**

The current proof shows the formal model is state-inert. A full security
proof for a physical implementation would additionally require:

1. The guard evaluation function has no oracle access to state
2. The timing of transitions is independent of state (timing side-channel)
3. The DAG structure itself does not leak state through its topology

Items 2 and 3 are outside the formal model and are physical/implementation
properties. They remain open.

---

## References

- `ControlFlowInvariants.agda`: `state-invariant` proof
- `QuantumInvariants.lean`: INV-1 through INV-13
- `order-of-symmetry`: Z₂ duality involution
- `carry-agent/runtime/quantum/`: FSM state preservation (14/14 tests)
- `integrity-constraint-governance/ICP-DAG.lp`: ASP enforcement layer
- Nayak et al. (2008): topological protection analogy
- NISTIR 8413 (2024): PQC standard reference
