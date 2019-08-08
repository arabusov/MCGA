#include <stdio.h>
#include <stdint.h>
#include "machine.h"

uint8_t test_prgr [] = {
    IS_LACC, 0x07, 0x04,
    IS_PUSH,
    IS_LACC, 0xba, 0xef,
    IS_PUSH,
    IS_LACC, 0x01, 0x03,
    IS_POP,
    IS_POP,
    IS_INV,
    IS_ADD,
    IS_LACC, 'A', 'B',
    IS_WRIT,
    IS_JZ,   0x08, 0x00,
    IS_HALT};

uint8_t echo_prgr [] =
{
    IS_READ,
    IS_WRIT,
    IS_JMP, 0x00, 0x00
};

uint8_t hello_world [] =
{
    IS_LACC,  'H', 0x00,
    IS_LMAC, 0x00, 0x00,
    IS_LACC,  'e', 0x00,
    IS_LMAC, 0x01, 0x00,
    IS_LACC,  'l', 0x00,
    IS_LMAC, 0x02, 0x00,
    IS_LACC,  'l', 0x00,
    IS_LMAC, 0x03, 0x00,
    IS_LACC,  'o', 0x00,
    IS_LMAC, 0x04, 0x00,
    IS_LACC,  ' ', 0x00,
    IS_LMAC, 0x05, 0x00,
    IS_LACC,  'w', 0x00,
    IS_LMAC, 0x06, 0x00,
    IS_LACC,  'o', 0x00,
    IS_LMAC, 0x07, 0x00,
    IS_LACC,  'r', 0x00,
    IS_LMAC, 0x08, 0x00,
    IS_LACC,  'l', 0x00,
    IS_LMAC, 0x09, 0x00,
    IS_LACC,  'd', 0x00,
    IS_LMAC, 0x0a, 0x00,
    IS_LACC,  '!', 0x00,
    IS_LMAC, 0x0b, 0x00,
    IS_LACC, '\n', 0x00,
    IS_LMAC, 0x0c, 0x00,
    IS_LACC, 0x00, 0x00,
    IS_PUSH,
    IS_POP,  /*jump here*/
    IS_LADR,
    IS_INC,
    IS_PUSH,
    IS_LAC,
    IS_WRIT,
    IS_LACC, 0x0d, 0x00,
    IS_SUB,
    IS_JZ,   55+14*3, 0x00,
    IS_JMP,  40+14*3, 0x00,
    IS_HALT
};

int main ()
{
    uint8_t i=0;
    FILE* fd;
    fd = fopen ("debug.out", "w");
    fprintf (fd, "Test program:\n");
    printf ("Machine IO (press Ctrl-C to exit):\n");
    for (i=0; i<sizeof (hello_world); i++)
        fprintf (fd, "0x%02x ", hello_world[i]);
    fprintf (fd, "\nInit...\n");
    machine_init (hello_world, sizeof (hello_world), fd);
    fprintf (fd, "Start:\n");
    machine_run (fd);
    fprintf (fd, "Done.\n");
    fclose (fd);
    return 0;
}
