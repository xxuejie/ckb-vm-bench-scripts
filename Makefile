CC := riscv64-unknown-elf-gcc
DUMP := riscv64-unknown-elf-objdump
HOST := riscv64-elf
CFLAGS := -Ideps/secp256k1/src -Ideps/secp256k1 -O3
LDFLAGS := -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -Wl,-s
SECP256K1_BENCH_BIN := build/secp256k1_bench
SCHNORR_BENCH_BIN := build/schnorr_bench_clang

all: $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

$(SECP256K1_BENCH_BIN): c/secp256k1_bench.c c/sha3.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

$(SCHNORR_BENCH_BIN): c/schnorr_bench.c c/sha3.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

clean:
	rm -rf $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

.PHONY: all clean
