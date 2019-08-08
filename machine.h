#pragma once
#include <stdint.h>
void machine_init (uint8_t * progr, uint16_t size);
void machine_run ();

#define INSTRUCTION_SIZE_BIT 0x80

/*SHORT INSTRUCTIONS*/
#define IS_HALT 0x01
#define IS_PUSH 0x02
#define IS_POP  0x03
#define IS_ADD  0x04
#define IS_INV  0x05
#define IS_INC  0x06

/*LONG INSTRUCTIONS*/
#define IS_LACC 0x81
#define IS_LMAC 0x82
#define IS_LACM 0x83
#define IS_JMP  0x84
#define IS_JZ   0x85
