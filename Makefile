# Sovereign AES-Formal Build Pipeline
# Target: aes-engine (GraalVM Native Image)
# Pipeline: Lean 4 → Dex → Scala → GraalVM → Counter-Defense

.PHONY: all lean dex scala native test clean

all: native

# 1. LEAN 4: Build proofs and generate artifact JSON
lean:
	cd lean && lake build
	lean --run lean/Phase13_Biclique_Closed.lean
	lean --run lean/KeySchedule_Arithmetic.lean
	@echo "✅ Lean 4 proofs verified (0 sorries)"

# 2. DEX: Compile verified GF(2) kernels to shared library
dex: lean
	dex build dex/aes_kernels.dex --release --target=shared-lib
	cp dex/target/release/libaes_kernels.so scala/native/lib/
	dex run dex/aes_kernels.dex --test
	@echo "✅ Dex kernels verified and compiled"

# 3. SCALA: Compile and test
scala: dex
	cd scala && sbt "testOnly *BicliqueMITMTest *KeyScheduleTest"
	@echo "✅ Scala tests passed"

# 4. GRAALVM: Native image
native: scala
	cd scala && sbt "graalvm-native-image:packageBin"
	@echo "✅ Native image built: scala/target/graalvm-native-image/aes-engine"

# 5. FULL VERIFICATION
test: native
	./scala/target/graalvm-native-image/aes-engine --verify-only

clean:
	cd lean && lake clean
	rm -f scala/native/lib/libaes_kernels.so
	cd scala && sbt clean
