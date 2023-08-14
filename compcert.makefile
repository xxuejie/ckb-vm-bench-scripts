CCOMP := ccomp
CLANG := clang-16
LD := ld.lld-16
DUMP := llvm-objdump-16
COMMON_CFLAGS := -O3 -g -I deps/secp256k1/src -nostdlib -I deps/ckb-c-stdlib/libc
COMPCERT_CFLAGS := $(COMMON_CFLAGS) -DUSE_EXTERNAL_ABORT \
	-D__SHARED_LIBRARY__ -DUSE_FORCE_WIDEMUL_INT128_STRUCT -fno-fpu -ffunction-sections -fdata-sections
CLANG_CFLAGS := $(COMMON_CFLAGS) --target=riscv64 -march=rv64imfdc_zba_zbb_zbc_zbs \
	-Wno-invalid-noreturn -ffunction-sections -fdata-sections -fvisibility=hidden \
	-DCKB_DECLARATION_ONLY -I deps/ckb-c-stdlib
LDFLAGS := --gc-sections -static -s
SECP256K1_BENCH_BIN := build/secp256k1_bench_compcert
SCHNORR_BENCH_BIN := build/schnorr_bench_compcert

all: $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN)

build/compcert_entry.o: c/compcert_entry.c
	$(CLANG) $(CLANG_CFLAGS) -c -o $@ $<

$(SECP256K1_BENCH_BIN): c/secp256k1_bench.c c/sha3.h build/compcert_entry.o
	$(CCOMP) $(COMPCERT_CFLAGS) -c -o build/secp256k1_bench_compcert.o $<
	$(LD) $(LDFLAGS) build/secp256k1_bench_compcert.o build/compcert_entry.o -o $@
	$(DUMP) -d $@ > $@_dump.txt

$(SCHNORR_BENCH_BIN): c/schnorr_bench.c c/sha3.h build/compcert_entry.o
	$(CCOMP) $(COMPCERT_CFLAGS) -c -o build/schnorr_bench_compcert.o $<
	$(LD) $(LDFLAGS) build/schnorr_bench_compcert.o build/compcert_entry.o -o $@
	$(DUMP) -d $@ > $@_dump.txt

clean:
	rm -rf $(SECP256K1_BENCH_BIN) $(SCHNORR_BENCH_BIN) build/*.o build/*_dump.txt

.PHONY: all clean
