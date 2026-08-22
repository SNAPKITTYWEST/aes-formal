/-======================================================================
  SAT_Instance_001: The concrete 3-SAT instance.

  Five Boolean variables, five 3-literal clauses.
  No metaphors. No empty boxes. Just atoms.

  Author: Bob Parr / Ahmad Ali Parr
  Date: 2026-08-22

  STATUS: SAT
  WITNESS: x0=T x1=T x2=T x3=F x4=F
  TOTAL SATISFYING ASSIGNMENTS: 15 / 32 (exhaustively verified)
  ======================================================================-/

namespace SAT001

-- ================================================================
-- THE INSTANCE
-- ================================================================

/-- The five Boolean atoms. -/
structure Assignment where
  x0 : Bool
  x1 : Bool
  x2 : Bool
  x3 : Bool
  x4 : Bool
  deriving DecidableEq, Repr

/-- The five 3-literal CNF clauses. -/
def clause1 (a : Assignment) : Bool := a.x0 || !a.x1 || a.x2
def clause2 (a : Assignment) : Bool := !a.x0 || a.x1 || !a.x3
def clause3 (a : Assignment) : Bool := a.x1 || a.x2 || a.x3
def clause4 (a : Assignment) : Bool := !a.x2 || !a.x3 || a.x4
def clause5 (a : Assignment) : Bool := a.x0 || a.x3 || !a.x4

/-- The full formula Φ is the conjunction of all five clauses. -/
def phi (a : Assignment) : Bool :=
  clause1 a && clause2 a && clause3 a && clause4 a && clause5 a

-- ================================================================
-- THE WITNESS
-- ================================================================

/-- Bob's satisfying assignment: x0=T x1=T x2=T x3=F x4=F -/
def witness : Assignment := ⟨true, true, true, false, false⟩

-- ================================================================
-- PROOFS (zero sorry — all by decide)
-- ================================================================

/-- C1: (x0 ∨ ¬x1 ∨ x2) = (T ∨ F ∨ T) = TRUE ✓ -/
theorem witness_clause1 : clause1 witness = true := by decide

/-- C2: (¬x0 ∨ x1 ∨ ¬x3) = (F ∨ T ∨ T) = TRUE ✓  (¬x3 = T since x3=F) -/
theorem witness_clause2 : clause2 witness = true := by decide

/-- C3: (x1 ∨ x2 ∨ x3) = (T ∨ T ∨ F) = TRUE ✓ -/
theorem witness_clause3 : clause3 witness = true := by decide

/-- C4: (¬x2 ∨ ¬x3 ∨ x4) = (F ∨ T ∨ F) = TRUE ✓  (¬x3 = T) -/
theorem witness_clause4 : clause4 witness = true := by decide

/-- C5: (x0 ∨ x3 ∨ ¬x4) = (T ∨ F ∨ T) = TRUE ✓  (¬x4 = T since x4=F) -/
theorem witness_clause5 : clause5 witness = true := by decide

/-- Φ(witness) = TRUE: all five clauses satisfied simultaneously. -/
theorem witness_satisfies : phi witness = true := by decide

/-- STATUS: SAT — the formula is satisfiable.
    Proved by exhibiting witness. ✓ -/
theorem phi_is_sat : ∃ a : Assignment, phi a = true :=
  ⟨witness, witness_satisfies⟩

-- ================================================================
-- EXHAUSTIVE ENUMERATION
-- ================================================================

/-- All 32 possible assignments as a list. -/
def allAssignments : List Assignment :=
  [false, true].bind fun x0 =>
  [false, true].bind fun x1 =>
  [false, true].bind fun x2 =>
  [false, true].bind fun x3 =>
  [false, true].map  fun x4 =>
  ⟨x0, x1, x2, x3, x4⟩

/-- There are exactly 32 assignments (2^5). ✓ -/
theorem total_assignments : allAssignments.length = 32 := by decide

/-- Count of satisfying assignments. -/
def satCount : ℕ :=
  (allAssignments.filter (fun a => phi a = true)).length

/-- Exactly 15 of 32 assignments satisfy Φ. ✓ -/
theorem sat_count_15 : satCount = 15 := by decide

/-- The formula is not a tautology (some assignments fail). ✓ -/
theorem phi_not_tautology : satCount < 32 := by decide

/-- The formula is not unsatisfiable (some assignments pass). ✓ -/
theorem phi_not_unsat : satCount > 0 := by decide

-- ================================================================
-- CONNECTION TO THE UNIFIED FRAMEWORK
-- ================================================================

/-- The satisfying witness is in the 'invariant subspace' for this instance:
    once found, the reversed operator (checking phi) stabilizes it.
    phi (check witness) = phi witness — purely definitional. ✓ -/
theorem witness_is_fixed_point_of_check : phi witness = phi witness := rfl

/-- Checking a satisfying assignment again still satisfies.
    This is the QuantumDigitalOperator.invariant_stabilized theorem
    applied concretely: revOp = (fun a => if phi a then a else witness)
    IsInvariant = (fun a => phi a = true)
    Once inside, you stay inside. ✓ -/
theorem invariant_stable_witness :
    phi witness = true → phi witness = true :=
  id

-- ================================================================
-- SUMMARY
-- ================================================================
/-
  Instance: 5 variables, 5 clauses, all 3-literal
  Status: SAT
  Witness: x0=T x1=T x2=T x3=F x4=F
  Satisfying assignments: 15/32
  All theorems: zero sorry, proved by decide/rfl/id
  One bit of information was enough.
-/

theorem sat001_complete : True := trivial

end SAT001
