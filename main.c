#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
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

int main (int argc, char**argv)
{
    uint8_t i=0;
    FILE *fd;
    FILE *input_file=NULL;
    uint8_t *program;
    size_t program_size;
    fd = fopen ("debug.out", "w");
    fprintf (fd, "Test program:\n");
    printf ("Machine IO (press Ctrl-C to exit):\n");
    /*Input*/
    if (argc==2)
        input_file = fopen (argv[1], "rb");
    if (input_file)
    {
        int ptr=0;
        fseek (input_file, 0L, SEEK_END);
        program_size = ftell (input_file);
        fseek (input_file, 0L, SEEK_SET);
        program = calloc (program_size, sizeof (uint8_t));
        fread (program, program_size, 1, input_file);
        fclose (input_file);
    }
    else
    {
        program = hello_world;
        program_size = sizeof (hello_world);
    }
    for (i=0; i<sizeof (program); i++)
    {
        fprintf (fd, "0x%02x ", program[i]);
        if (i%16) fprintf (fd, "\n");
    }
    fprintf (fd, "\nInit...\n");
    machine_init (program, program_size, fd);
    fprintf (fd, "Start:\n");
    machine_run (fd);
    fprintf (fd, "Done.\n");
    fclose (fd);
    if (input_file && program)
        free (program);
    return 0;
}
