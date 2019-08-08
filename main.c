#include <stdio.h>
#include <stdint.h>
#include "machine.h"

#define TEST_PRGR_SIZE 19
uint8_t test_prgr [TEST_PRGR_SIZE] = {
    IS_LACC, 0x07, 0x04,
    IS_PUSH,
    IS_LACC, 0xba, 0xef,
    IS_PUSH,
    IS_LACC, 0x01, 0x03,
    IS_POP,
    IS_POP,
    IS_INV,
    IS_ADD,
    IS_JZ, 0x08, 0x00,
    IS_HALT};

int main ()
{
    uint8_t i=0;
    printf ("Test program:\n");
    for (i=0; i<TEST_PRGR_SIZE; i++)
        printf ("0x%02x ", test_prgr [i]);
    printf ("\nInit...\n");
    machine_init (test_prgr, TEST_PRGR_SIZE);
    printf ("Start.\n");
    machine_run ();
    printf ("Done.\n");
    return 0;
}
