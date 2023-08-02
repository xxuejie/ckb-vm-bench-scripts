CC := clang-16
DUMP := llvm-objdump-16
CFLAGS := -Ideps/secp256k1/src -Ideps/secp256k1 -O3 \
	-nostdlib -nostdinc -Ideps/ckb-c-stdlib -Ideps/ckb-c-stdlib/libc -DUSE_CKB_C_STDLIB \
	--target=riscv64 -march=rv64imc_zba_zbb_zbc_zbs \
	-Wno-pointer-sign -Wno-invalid-noreturn
LDFLAGS := -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -Wl,-s
SECP256K1_LIB := deps/secp256k1/src/ecmult_static_pre_context.h
SECP256K1_BENCH_BIN := build/secp256k1_bench_clang
SCHNORR_BENCH_BIN := build/schnorr_bench_clang

all: $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

$(SECP256K1_BENCH_BIN): c/secp256k1_bench.c c/sha3.h $(SECP256K1_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

$(SCHNORR_BENCH_BIN): c/schnorr_bench.c c/sha3.h $(SECP256K1_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

$(SECP256K1_LIB):
	cd deps/secp256k1 && \
		./autogen.sh && \
		./configure --with-bignum=no --enable-ecmult-static-precomputation --enable-endomorphism --enable-module-recovery --enable-module-extrakeys --enable-module-schnorrsig --enable-experimental --with-asm=no && \
		make

clean:
	cd deps/secp256k1 && make clean
	rm -rf $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

.PHONY: all clean
