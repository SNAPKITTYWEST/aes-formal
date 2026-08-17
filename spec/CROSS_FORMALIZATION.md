# CROSS-FORMALIZATION EQUIVALENCE MATRIX

## Language Coverage

| Layer | Lean 4 | Agda | Coq | Isabelle | SMT-LIB | OpenQASM | Rust | Python |
|-------|--------|------|-----|----------|---------|----------|------|--------|
| Primitives | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Definitions | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Axioms | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | N/A | N/A |
| Algorithms | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Invariants | ✅ | ✅ | ✅ | ✅ | ✅ | N/A | ✅ | ✅ |
| Correctness | ✅ | ✅ | ✅ | ✅ | ❌ | N/A | ❌ | ❌ |
| Complexity | ✅ | ✅ | ✅ | ✅ | ❌ | N/A | ✅ | ✅ |
| Implementation | ✅ | ❌ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |

✅ = Complete &nbsp; 🔄 = In Progress &nbsp; ❌ = Not Applicable

## Expressiveness Comparison

| Feature | Lean 4 | Coq | Agda | Isabelle | SMT-LIB | OpenQASM |
|---------|--------|-----|------|----------|---------|----------|
| Dependent Types | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Classical Logic | ✅ | ✅ | ❌ | ✅ | ✅ | ❌ |
| Computational Reflection | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ |
| Quantum Circuits | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| Polynomial Arithmetic | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Complexity Theory | ✅ | ✅ | ⚠️ | ✅ | ❌ | ❌ |
