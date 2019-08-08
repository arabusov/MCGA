#include <stdio.h>
#include <stdint.h>
#include <unistd.h>
#include <string.h>
#include "machine.h"

int exit_flag = 0;
uint8_t mem [0x10000];
uint8_t stack [0x10000];
uint8_t code [0x10000];
FILE * fd;

struct regs
{
    uint16_t accu;
    uint16_t ip;
    uint16_t sp;
    uint16_t addr;
} machine_regs;

struct state
{
    int halt;
    int jump;
    uint16_t instruction_size;
    uint8_t instruction_l;
    uint16_t instruction_h;
} machine_state;
    
void determine_instruction_size ()
{
    if (code[machine_regs.ip]&INSTRUCTION_SIZE_BIT)
        machine_state.instruction_size = 3;
    else
        machine_state.instruction_size = 1;
}

void print_state ()
{
    if (machine_state.halt)
        fprintf (fd, "Halt.\n");
    else
    {
        uint16_t i = 0;
        fprintf (fd, "========================================================\n");
        fprintf (fd, "Regs: ACCU: 0x%04x, IP: 0x%04x, SP: 0x%04x, ADDR: 0x%04x\n",
            machine_regs.accu, machine_regs.ip, machine_regs.sp,
            machine_regs.addr);
        fprintf (fd, "State: IL: 0x%02x, IH: 0x%04x, HALT: %d, ISIZE: %d, JMP %d\n",
            machine_state.instruction_l, machine_state.instruction_h,
            machine_state.halt, machine_state.instruction_size,
            machine_state.jump);
        fprintf (fd, "Stack: ");
        for (i=0; i<0xf;i++)
            fprintf (fd, "%02x ", stack[i]);
        fprintf (fd, "\n");
    }
    fflush (fd);
    return;
}

void machine_init (uint8_t * progr, uint16_t size, FILE* _fd)
{
    fd = _fd;
    machine_regs.accu = 0;
    machine_regs.ip = 0;
    machine_regs.sp = 0;
    machine_regs.addr = 0;
    machine_state.halt = 0;
    machine_state.jump = 0;
    memcpy (code, progr, size);
    exit_flag = 0;
    print_state ();
    return;
}

void read_instruction ()
{
    machine_state.instruction_l = code[machine_regs.ip];
    if (machine_state.instruction_size == 3)
    {
        machine_state.instruction_h = code[machine_regs.ip+1] +
            (((uint16_t)code[machine_regs.ip+2])<<8);
    }
}

void parse_instruction ()
{
    if (machine_state.instruction_l == IS_HALT)
    {
        machine_state.halt = 1;
        return;
    }
    if (machine_state.instruction_size == 3)
    {
        if (machine_state.instruction_l == IS_LACC) /* load accumulator from const */
        {
            machine_regs.accu = machine_state.instruction_h;
            return;
        }
        if (machine_state.instruction_l == IS_LACM)/*load accumulator from memory */
        {
            machine_regs.accu = mem [machine_state.instruction_h]; 
            return;
        }
        if (machine_state.instruction_l == IS_LMAC)/*load in memory from accumulator*/
        {
            mem [machine_state.instruction_h] = machine_regs.accu;
            return;
        }
        if (machine_state.instruction_l == IS_JMP)
        {
            machine_regs.ip = machine_state.instruction_h;
            machine_state.jump = 1;
            return;
        }
        if (machine_state.instruction_l == IS_JZ)
        {
            if (machine_regs.accu == 0)
            {
                machine_regs.ip = machine_state.instruction_h;
                machine_state.jump = 1;
            }
            return;
        }
    }
    if (machine_state.instruction_size == 1)
    {
        if (machine_state.instruction_l == IS_PUSH)
        {
            stack[machine_regs.sp++] = (uint8_t)(machine_regs.accu&0xff);
            stack[machine_regs.sp++] = (uint8_t)((machine_regs.accu&0xff00)>>8);
            return;
        }
        if (machine_state.instruction_l == IS_POP)
        {
            machine_regs.accu = (uint16_t)(stack[--machine_regs.sp])<<8;
            machine_regs.accu += (uint16_t)(stack[--machine_regs.sp]);
            return;
        }
        if (machine_state.instruction_l == IS_ADD)
        {
            machine_regs.accu += (uint16_t)stack[machine_regs.sp-2]+
                (((uint16_t)stack[machine_regs.sp-1])<<8);
            return;
        }
        if (machine_state.instruction_l == IS_SUB)
        {
            machine_regs.accu = (uint16_t)((int16_t)machine_regs.accu-
            (int16_t)((uint16_t)stack[machine_regs.sp-2]+
                (((uint16_t)stack[machine_regs.sp-1])<<8)));
            return;
        }
        if (machine_state.instruction_l == IS_INV)
        {
            machine_regs.accu = ~machine_regs.accu;
            return;
        }
        if (machine_state.instruction_l == IS_INC)
        {
            machine_regs.accu++;
            return;
        }
        if (machine_state.instruction_l == IS_WRIT)
        {
            putchar ((uint8_t)machine_regs.accu);
            fflush (stdout);
            return;
        }
        if (machine_state.instruction_l == IS_READ)
        {
            machine_regs.accu = (uint16_t)getchar_unlocked();
            return;
        }
        if (machine_state.instruction_l == IS_LADR)
        {
            machine_regs.addr = machine_regs.accu;
            return;
        }
        if (machine_state.instruction_l == IS_LAC)
        {
            machine_regs.accu = (uint8_t)mem[machine_regs.addr];
            return;
        }
    }
}

void machine_run ()
{
    while (!exit_flag)
    {
        read_instruction ();
        determine_instruction_size ();
        read_instruction ();
        parse_instruction ();
        print_state ();
        if (!machine_state.halt)
            if (!machine_state.jump)
                if (machine_state.instruction_size == 3)
                    machine_regs.ip += 3;
                else
                    machine_regs.ip += 1;
            else
                machine_state.jump = 0;
        else
            exit_flag = 1;
        sleep (1);
    }
    return;
}
