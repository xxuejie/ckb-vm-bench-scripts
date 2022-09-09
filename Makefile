CC := riscv64-unknown-elf-gcc
DUMP := riscv64-unknown-elf-objdump
TIMES := 10000
CFLAGS := -Ideps/secp256k1/src -Ideps/secp256k1 -O3 -g -DSECP_TIMES=$(TIMES)
LDFLAGS := -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections
SECP256K1_LIB := deps/secp256k1/src/ecmult_static_pre_context.h
SECP256K1_BENCH_BIN := build/secp256k1_bench

all: $(SECP256K1_BENCH_BIN) build/schnorr_bench build/secp256k1_bench_$(TIMES) build/secp256k1_bench_$(TIMES)_native

$(SECP256K1_BENCH_BIN): c/secp256k1_bench.c c/sha3.h $(SECP256K1_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

build/schnorr_bench: c/schnorr_bench.c c/sha3.h $(SECP256K1_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

build/secp256k1_bench_$(TIMES): c/secp256k1_bench_times.c c/sha3.h $(SECP256K1_LIB)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

build/secp256k1_bench_$(TIMES)_native: c/secp256k1_bench_times.c c/sha3.h $(SECP256K1_LIB)
	gcc $(CFLAGS) -o $@ $<
	objdump -d $@ > $@_dump.txt

$(SECP256K1_LIB):
	cd deps/secp256k1 && \
		./autogen.sh && \
		CC=riscv64-unknown-elf-gcc LD=riscv64-unknown-elf-gcc ./configure --with-bignum=no --enable-ecmult-static-precomputation --enable-endomorphism --enable-module-recovery --enable-module-extrakeys --enable-module-schnorrsig --enable-experimental --host=riscv64-elf && \
		make

clean:
	cd deps/secp256k1 && make clean
	rm -rf build/s*

.PHONY: all clean
