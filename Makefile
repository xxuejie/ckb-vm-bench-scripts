CC := riscv64-unknown-elf-gcc
DUMP := riscv64-unknown-elf-objdump
HOST := riscv64-elf
CFLAGS := -Ideps/secp256k1/src -Ideps/secp256k1 -O3
LDFLAGS := -Wl,-static -fdata-sections -ffunction-sections -Wl,--gc-sections -Wl,-s
SECP256K1_BENCH_BIN := build/secp256k1_bench
SCHNORR_BENCH_BIN := build/schnorr_bench

# docker pull nervos/ckb-riscv-gnu-toolchain:jammy-20230214
BUILDER_DOCKER := nervos/ckb-riscv-gnu-toolchain@sha256:980b93b3ecb4e7c825d3d50f3ec9a3817fc3dbf952c14694b6cb91623602ae9e

all: $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

all-via-docker:
	docker run --rm -v `pwd`:/code ${BUILDER_DOCKER} bash -c "cd /code && make"

$(SECP256K1_BENCH_BIN): c/secp256k1_bench.c c/sha3.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

$(SCHNORR_BENCH_BIN): c/schnorr_bench.c c/sha3.h
	$(CC) $(CFLAGS) $(LDFLAGS) -o $@ $<
	$(DUMP) -d $@ > $@_dump.txt

clean:
	rm -rf $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

.PHONY: all clean
