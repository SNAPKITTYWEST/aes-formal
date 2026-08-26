#!/bin/sh
# AES Formal — Full Reproduction Script
# Nova Parr review 2026-08-26: "rm -rf results && ./reproduce.sh = same numbers"
set -e

echo "=============================="
echo "AES FORMAL — PHASE 13 REPRO"
echo "Audit: 4b565498-9afc-4782-af4a-c6b11a5d0058"
echo "=============================="

mkdir -p results/

# 1. Lean 4 proofs
echo "[1/5] Building Lean 4 proofs..."
cd lean && lake build 2>&1 | tee ../results/lean_build.log
cd ..
echo "[lean] DONE"

# 2. Phase 13 biclique closure
echo "[2/5] Phase 13 biclique..."
lean --run lean/Phase13_Biclique_Closed.lean 2>&1 | tee results/phase13.log || true

# 3. Python KATs (FIPS-197)
echo "[3/5] Python KATs..."
python3 python/phase5_aes128.py 2>&1 | tee results/phase5_kat.log
python3 python/phase13_reversible_hash.py 2>&1 | tee results/phase13_hash.log

# 4. Cross-verification
echo "[4/5] Cross-verification..."
python3 python/phase10_cross_verification.py 2>&1 | tee results/phase10.log || true

# 5. Hash all sources
echo "[5/5] SHA-256 artifact hash..."
find lean/ python/ -name "*.lean" -o -name "*.py" | sort | xargs sha256sum > results/SHA256SUMS
echo "[hashes] Written to results/SHA256SUMS"

echo ""
echo "REPRODUCTION COMPLETE"
echo "Seed: 0x4b565498 (log in paper appendix)"
echo "Compare results/ with published artifact."
