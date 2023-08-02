#include <stdlib.h>
#include <string.h>
#include "sha3.h"

#define SHA3_BLOCK_SIZE 32

/*
 * We are including secp256k1 implementation directly so gcc can strip
 * unused functions. For some unknown reasons, if we link in libsecp256k1.a
 * directly, the final binary will include all functions rather than those used.
 */
#define HAVE_CONFIG_H 1
#define USE_EXTERNAL_DEFAULT_CALLBACKS
#include <secp256k1.c>

#ifdef USE_CKB_C_STDLIB
#include "ckb_syscalls.h"
void abort() {
  ckb_exit(-1);
}
#endif

void secp256k1_default_illegal_callback_fn(const char* str, void* data) {
  (void) str;
  (void) data;
  abort();
}

void secp256k1_default_error_callback_fn(const char* str, void* data) {
  (void) str;
  (void) data;
  abort();
}

int secp256k1_custom_verify_only_initialize(secp256k1_context *context,
                                            secp256k1_ge_storage (*pre_g)[],
                                            secp256k1_ge_storage (*pre_g_128)[]) {
  context->illegal_callback = default_illegal_callback;
  context->error_callback = default_error_callback;

  secp256k1_ecmult_context_init(&context->ecmult_ctx);
  secp256k1_ecmult_gen_context_init(&context->ecmult_gen_ctx);

  context->ecmult_ctx.pre_g = pre_g;
  context->ecmult_ctx.pre_g_128 = pre_g_128;

  return 1;
}

int char_to_int(char ch)
{
  if (ch >= '0' && ch <= '9') {
    return ch - '0';
  }
  if (ch >= 'a' && ch <= 'f') {
    return ch - 'a' + 10;
  }
  return -1;
}

int hex_to_bin(char* buf, size_t buf_len, const char* hex)
{
  int i = 0;

  for (; i < buf_len && hex[i * 2] != '\0' && hex[i * 2 + 1] != '\0'; i++) {
    int a = char_to_int(hex[i * 2]);
    int b = char_to_int(hex[i * 2 + 1]);

    if (a < 0 || b < 0) {
      return -1;
    }

    buf[i] = ((a & 0xF) << 4) | (b & 0xF);
  }

  if (i == buf_len && hex[i * 2] != '\0') {
    return -1;
  }
  return i;
}

#define CHECK_LEN(x) if ((x) <= 0) { return x; }

/*
 * Arguments are listed in the following order:
 * 0. Program name, ignored here, only preserved for compatibility reason
 * 1. Pubkey in hex format, a maximum of 130 bytes will be processed
 * 2. Signature in hex format, a maximum of 512 bytes will be processed
 * 3. Current script hash in hex format, which is 128 bytes. While this program
 * cannot verify the hash directly, this ensures the script is include in
 * signature calculation
 * 4. Other additional parameters that might be included. Notice only ASCII
 * characters are included, so binary should be passed as binary format.
 *
 * This program will run double sha256 on all arguments excluding pubkey and
 * signature(also for simplicity, we are running sha256 on ASCII chars directly,
 * not deserialized raw bytes), then it will use sha256 result calculated as the
 * message to verify the signature. It returns 0 if the signature works, and
 * a non-zero value otherwise.
 *
 * Note all hex values passed in as arguments must have lower case letters for
 * deterministic behavior.
 */
int main(int argc, char* argv[])
{
  char buf[256];
  int len;

  if (argc < 4) {
    return -1;
  }

  secp256k1_context context;
  int ret = secp256k1_custom_verify_only_initialize(
      &context,
      (secp256k1_ge_storage (*)[]) &secp256k1_ecmult_static_pre_context,
      (secp256k1_ge_storage (*)[]) &secp256k1_ecmult_static_pre128_context);
  if (ret == 0) {
    return 4;
  }

  len = hex_to_bin(buf, 65, argv[1]);
  CHECK_LEN(len);
  secp256k1_pubkey pubkey;

  ret = secp256k1_ec_pubkey_parse(&context, &pubkey, buf, len);
  if (ret == 0) {
    return 1;
  }

  len = hex_to_bin(buf, 256, argv[2]);
  CHECK_LEN(len);
  secp256k1_ecdsa_signature signature;
  secp256k1_ecdsa_signature_parse_der(&context, &signature, buf, len);
  if (ret == 0) {
    return 3;
  }

  sha3_ctx_t sha3_ctx;
  unsigned char hash[SHA3_BLOCK_SIZE];
  sha3_init(&sha3_ctx, SHA3_BLOCK_SIZE);
  for (int i = 3; i < argc; i++) {
    sha3_update(&sha3_ctx, argv[i], strlen(argv[i]));
  }
  sha3_final(hash, &sha3_ctx);

  sha3_init(&sha3_ctx, SHA3_BLOCK_SIZE);
  sha3_update(&sha3_ctx, hash, SHA3_BLOCK_SIZE);
  sha3_final(hash, &sha3_ctx);

  ret = secp256k1_ecdsa_verify(&context, &signature, hash, &pubkey);
  if (ret == 1) {
    ret = 0;
  } else {
    ret = 2;
  }

  return ret;
}
