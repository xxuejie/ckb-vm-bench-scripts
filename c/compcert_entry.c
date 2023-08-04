#include "ckb_syscalls.h"
void abort() {
  ckb_exit(-1);
}

extern int main(int argc, char* argv[]);

__attribute__((visibility("default"))) __attribute__((naked)) void _start() {
  asm volatile(
      ".option push\n"
      ".option norelax\n"
      /*
       * By default CKB VM initializes all memory to 0, there's no need
       * to clear BSS segment again.
       */
      "lw a0, 0(sp)\n"
      "addi a1, sp, 8\n"
      "li a2, 0\n"
      "call main\n"
      "li a7, 93\n"
      "ecall");
}
