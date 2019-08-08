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

int main ()
{
    uint8_t i=0;
    FILE* fd;
    fd = fopen ("debug.out", "w");
    fprintf (fd, "Test program:\n");
    printf ("Machine IO (press Ctrl-C to exit):\n");
    for (i=0; i<sizeof (echo_prgr); i++)
        fprintf (fd, "0x%02x ", echo_prgr [i]);
    fprintf (fd, "\nInit...\n");
    machine_init (echo_prgr, sizeof (echo_prgr), fd);
    fprintf (fd, "Start:\n");
    machine_run (fd);
    fprintf (fd, "Done.\n");
    fclose (fd);
    return 0;
}
