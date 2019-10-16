bits 16
cpu 286

%include "atix.inc"
%include "fat12.inc"

code_size   equ         end_code - start
stack_limit equ         ATIX_STACK_ABS - (ATIX_ABS + code_size + data_size + \
tss_size)
section .text
org ATIX_OFFSET
;----------------------------------------------------------------------------;
;                               CODE SEGMENT                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;

start:

;---------------------------------------;
;        Initialization procedure       ;
;                                       ;
; The kernel is in real mode.           ;
;                                       ;
;---------------------------------------;

;---------------------------------------;
;           Mask interrupts             ;
;---------------------------------------;

            cli

            mov         al, 0x11        ; Also, set up all two interrupt
            out         0x20, al        ; controllers and mask all hardware
                                        ; interrupts in addition to cli
            out         0xa0, al        ; instruction.

            mov         al, IRQ0        ; Remap hardware interrupts away
            out         0x21, al        ; of i286 processor 
            mov         al, IRQ8        ; interrupt "addresses".
            out         0xa1, al

            mov         al, 0x04        ; PIC1 is in "master" mode.
            out         0x21, al
            mov         al, 0x02        ; PIC2 is in "slave" mode.
            out         0xa1, al

            mov         al, 0x01        ; Initialization command word No. 4
            out         0x21, al        
            out         0xa1, al

            mov         al, 0xff        ; And, finally, disable all interrupt
            out         0x21, al        ; requests.

;---------------------------------------;
;        Initialize segment registers   ;
;---------------------------------------;
            mov         ax, ATIX_SEG    ; Set all segment registers
            mov         ds, ax
            mov         es, ax
            mov         ss, ax
            mov         sp, ATIX_STACK_OFFSET

;---------------------------------------;
;       Print a "hello" message         ;
;---------------------------------------;

            call        clrscr          ; Clear screen and print a "hello"
                                        ; message.
            mov         bp, atixmsg
            mov         cx, atixmsgln
            call        println

;---------------------------------------;
;           Set A20 line on             ;
;---------------------------------------;

            ;mov         al, 0xdd
            ;out         0x64, al

;---------------------------------------;
;               Debug GDT               ;
;---------------------------------------;

realm_ip:   call        debug_gdt

;---------------------------------------;
;       Debug the real -> protected     ;
; mode switching.                       ;
;---------------------------------------;

            mov         ax, 0xb800
            mov         es, ax
            mov         word [es:79*2], 0x8252

            lgdt        [gdt.gdt_desc]
            lidt        [idt_desc]
            smsw        ax
            or          ax, PM_BIT
            lmsw        ax
            jmp         code_sel:pm_pipeline
pm_pipeline:
            mov         ax, video_sel
            mov         es, ax
            mov         word [es:79*2+80*2], 0xc050
            mov         ax, stack_sel
            mov         ss, ax
            mov         sp, 0
            mov         ax, data_sel
            mov         ds, ax
            mov         ax, video_sel
            mov         es, ax

            mov         bp, msg.pm
            mov         cx, msg.pmln
            call        println
;---------------------------------------;
;           Test exceptions             ;
;---------------------------------------;
            sti
            int         0x00       ; GP

;---------------------------------------;
;           Halt processor              ;
;---------------------------------------;

            mov         bp, haltmsg
            mov         cx, haltmsgln
            call        println

atix_halt:
            hlt
            jmp         atix_halt-ATIX_OFFSET

check_mode:
            smsw        ax
            and         ax, PM_BIT
            ret

;----------------------------------------------------------------------------;
;                            Real mode routines                              ;
;                                                                            ;
;----------------------------------------------------------------------------;

;---------------------------------------;
;           Debug GDT routine           ;
;---------------------------------------;

debug_gdt:
            mov         bp, msg.debug_gdt
            mov         cx, msg.debug_gdtln
            call        println

            mov         bp, msg.curr_csip
            mov         cx, msg.curr_csipln
            call        print
            mov         ax, cs
            mov         al, ah
            call        printal
            mov         ax, cs
            call        printal
            mov         bp, msg.colon
            mov         cx, 1
            call        print
            mov         ax, pm_pipeline
            mov         al, ah
            call        printal
            mov         ax, pm_pipeline
            call        printal
            call        newline

            mov         bp, msg.gdt_desc
            mov         cx, msg.gdt_descln
            call        print
            
            mov         al, [gdt.gdt_desc+5]
            call        printal
            call        newline

            mov         bp, msg.code_desc
            mov         cx, msg.code_descln
            call        print
            
            mov         al, [gdt.code_desc+5]
            call        printal
            call        newline

            mov         bp, msg.code_base
            mov         cx, msg.code_baseln
            call        print
            
            mov         al, [gdt.code_desc+4]
            call        printal
            mov         al, [gdt.code_desc+3]
            call        printal
            mov         al, [gdt.code_desc+2]
            call        printal
            call        newline

            mov         bp, msg.code_desc_pos
            mov         cx, msg.code_desc_posln
            call        print
            
            mov         ax, (gdt.code_desc - gdt)
            mov         al, ah
            call        printal
            mov         ax, (gdt.code_desc - gdt)
            call        printal
            call        newline

            mov         bp, msg.code_sel
            mov         cx, msg.code_selln
            call        print
            
            mov         ax, code_sel
            mov         al, ah
            call        printal
            mov         ax, code_sel
            call        printal
            call        newline

            mov         bp, msg.code_limit
            mov         cx, msg.code_limitln
            call        print
            
            mov         al, [gdt.code_desc+1]
            call        printal
            mov         al, [gdt.code_desc]
            call        printal
            call        newline

            mov         bp, msg.tss_desc
            mov         cx, msg.tss_descln
            call        print
            
            mov         al, [gdt.ktss_desc+5]
            call        printal
            call        newline

            mov         bp, msg.video_desc
            mov         cx, msg.video_descln
            call        print
            
            mov         al, [gdt.video_desc+5]
            call        printal
            call        newline

            mov         bp, msg.stack_desc
            mov         cx, msg.stack_descln
            call        print
            
            mov         al, [gdt.stack_desc+5]
            call        printal
            call        newline

            mov         bp, msg.data_desc
            mov         cx, msg.data_descln
            call        print
            
            mov         al, [gdt.data_desc+5]
            call        printal
            call        newline

            mov         bp, msg.data_sel
            mov         cx, msg.data_selln
            call        print
            
            mov         ax, data_sel
            mov         al, ah
            call        printal
            mov         ax, data_sel
            call        printal
            call        newline

            mov         bp, msg.idt_size
            mov         cx, msg.idt_sizeln
            call        print
            mov         ax, idt_size
            call        printaxln

            ret

;----------------------------------------------------------------------------;
;                               Screen routines                              ;
; They should be capable for both real and protected modes.                  ;
;                                                                            ;
;----------------------------------------------------------------------------;

;----------------------------------------------------------------------------;
;                             Clear screen routine                           ;
;                                                                            ;
;----------------------------------------------------------------------------;

clrscr:
            push        bx
            push        cx
            push        ds

            mov         ax, SCRSEG
            mov         ds, ax

            mov         cx, SCRNCL*SCRNRW*2

.loop:      mov         bx, cx
            mov         word [bx], 0x0002
            loop        .loop

            mov         bx, 0
            call        mvcurs

            pop         ds
            pop         cx
            pop         bx
            ret
;----------------------------------------------------------------------------;
;                           Print line routine                               ;
;                                                                            ;
;----------------------------------------------------------------------------;

println:
            pusha
            push        es
            push        ds
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, ATIX_SEG
            mov         ds, ax
            mov         es, ax
            jmp         .continue

.pm:        mov         ax, data_sel
            mov         es, ax
            mov         ds, ax
.continue:
            mov         bx, [crsps]
            call        mvcurs
            shl         bx,1
            call        print
            call        newline

            pop         ds
            pop         es
            popa
            ret

;----------------------------------------------------------------------------;
;                             Print routine                                  ;
;                                                                            ;
;----------------------------------------------------------------------------;

print:  
            pusha
            push        es
            push        ds
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, SCRSEG
            mov         ds, ax
            mov         ax, ATIX_SEG
            mov         es, ax
            jmp         .continue

.pm:        mov         ax, data_sel
            mov         es, ax
            mov         ax, video_sel
            mov         ds, ax
.continue:
            cmp         cx,0
            jz          endprn
            mov         bx,[es:crsps]
            shl         bx,1
            mov         ah, 0x02
get_symbol:
            mov         al, [es:bp]
            cmp         al, 13 ;newline
            jnz         check_10
            push        bx
            shr         bx,1
            mov         [es:crsps],bx
            call        mvcurs
            call        newline
            pop         bx
            inc         bp
            dec         cx
            jz          endprn
            jmp         get_symbol
check_10:
            cmp         al,10
            jnz         contprint1
            push        ax
            mov         ax,bx
            mov         bl,SCRNCL
            div         bl
            mov         bl,SCRNCL
            mul         bl
            mov         bx,ax
            pop         ax
            inc         bp
            dec         cx
            jz          endprn
            jmp         get_symbol

contprint1:
            cmp         bx, SCRNCL*SCRNRW*2
            jb          contprint2
            call        nl
            mov         bx,SCRNCL*(SCRNRW-1)*2
            push        bx
            shr         bx,1
            call        mvcurs
            pop         bx
contprint2:
            mov         [bx], ax
            add         bx, 2
            inc         bp
            loop        get_symbol

endprn:
            shr         bx,1
            call        mvcurs
            pop         ds
            pop         es
            popa
            ret

mvcurs:
            pusha
            push        es
            push        ds
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, ATIX_SEG
            mov         ds, ax
            mov         es, ax
            jmp         .continue

.pm:        mov         ax, data_sel
            mov         ds, ax
            mov         es, ax
.continue:
            mov         [crsps], bx     ;save the position
            mov         dx, 0x03d4
            mov         al, 0x0f
            out         dx, al

            inc         dl
            mov         al, bl
            out         dx, al

            dec         dl
            mov         al, 0x0e
            out         dx, al

            inc         dl
            mov         al, bh
            out         dx, al

            pop         ds
            pop         es
            popa
            ret


;----------------------------------------------------------------------------;
;                             Newline subroutines                            ;
;                                                                            ;
;----------------------------------------------------------------------------;

nl:
            pusha
            push        es
            push        ds
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, SCRSEG
            mov         ds, ax
            mov         es, ax
            jmp         .continue

.pm:        mov         ax, video_sel
            mov         ds, ax
            mov         es, ax
.continue:
            mov         di, 0x00
            mov         si, SCRNCL*2
            mov         cx, SCRNCL*(SCRNRW-1)*2
            cld
            rep
            movsb
            mov         di, SCRNCL*(SCRNRW-1)*2
            mov         cx, SCRNCL
            mov         ax, 0x0200
clearln:
            mov         [di],ax
            add         di,2
            loop        clearln

            pop         ds
            pop         es
            popa
            ret

newline:
            pusha
            push        es
            push        ds
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, ATIX_SEG
            mov         ds, ax
            mov         es, ax
            jmp         .continue

.pm:        mov         ax, data_sel
            mov         ds, ax
            mov         es, ax
.continue:
            mov         ax, [crsps]
            mov         bl,SCRNCL
            div         bl
            cmp         al, SCRNRW
            je          cnl
            add         al,1
            mov         ah,0
            mov         bx,SCRNCL
            mul         bl
            mov         bx,ax
            call        mvcurs
            jmp         endprint

cnl:
            call        nl
            mov         bx,SCRNCL*(SCRNRW-1)
            call        mvcurs
endprint:
            pop         ds
            pop         es
            popa
            ret
;----------------------------------------------------------------------------;
;                         Print AL register routine                          ;
;                                                                            ;
;----------------------------------------------------------------------------;
printal:
            push        ds
            push        bp
            push        cx
            push        dx
            push        bx
            push        ax
            
            call        check_mode
            cmp         ax, PM_BIT
            jz          .pm
            mov         ax, ATIX_SEG
            mov         ds, ax
            jmp         .continue

.pm:        mov         ax, data_sel
            mov         ds, ax
.continue:
            pop         ax
            push        ax
            mov         bx, hex_table
            mov         dl, al              ; Temporary storage in DL
            shr         al, 4
            xlat        
            mov         ah, al
            mov         al, dl
            and         al, 0x0f
            xlat
            xchg        al, ah
            mov         [al_print], ax
            mov         cx, 2
            mov         bp, al_print
            call        print

            pop         ax
            pop         bx
            pop         dx
            pop         cx
            pop         bp
            pop         ds
            ret

printalln:
            call        printal
            call        newline
            ret

;----------------------------------------------------------------------------;
;                      Processor exceptions procedures                       ;
;                                                                            ;
;----------------------------------------------------------------------------;
printax:
            mov         dl,al
            mov         al, ah
            call        printal
            mov         ax, dx
            call        printal

            ret

printaxln:
            call        printax
            call        newline
            ret

kernel_panic:
            call        printaxln
            mov         bp, msg.kernel_panic
            mov         cx, msg.kernel_panicln
            call        println

            mov         bp, msg.nexc
            mov         cx, msg.nexcln
            call        print
            call        printalln

            cmp         al, 0x08
            je          .errcode
            cmp         al, 0x0a
            jb          .no_errcode
            cmp         al, 0x0d
            jbe         .errcode
            cmp         al, 0x20
            jb          .reserved
            cmp         al, 0x30
            jb          .hardware
            jmp         .other
.errcode:
            mov         bp, msg.errcode
            mov         cx, msg.errcodeln
            call        print
            pop         ax
            call        printaxln

.no_errcode:
            mov         bp, msg.oldcsip
            mov         cx, msg.oldcsipln
            call        print
            mov         bp, sp
            mov         ax, [ss:bp+2]
            call        printax
            mov         bp, msg.colon
            mov         cx, 1
            call        print
            mov         bp, sp
            mov         ax, [ss:bp]
            call        printaxln
            jmp         .halt_msg
.reserved:
            mov         bp, msg.res_exc
            mov         cx, msg.res_excln
            call        println
            jmp         .halt_msg
.hardware:
            mov         bp, msg.hardware_int
            mov         cx, msg.hardware_int
            call        println
            jmp         .halt_msg

.other:     mov         bp, msg.other_int
            mov         cx, msg.other_intln
            call        println

.halt_msg:
            mov         bp, haltmsg
            mov         cx, haltmsgln
            call        println

.halt:      hlt
            jmp         .halt

;---------------------------------------;
;       Default exception handler       ;
;---------------------------------------;

%macro DEFAULT_EXCEPTION 1
exc%1_h:    
            cli 
            mov         ax, %1
            call        kernel_panic
%endmacro

;---------------------------------------;
;     Processor exception handlers      ;
;---------------------------------------;

%assign i 0
%rep    0x20
            DEFAULT_EXCEPTION %[i]
            %assign i i+1
%endrep

;---------------------------------------;
;  Default hardware interrupt handler   ;
;---------------------------------------;

%macro DEFAULT_INTERRUPT 1
int%1_h:    cli 
            mov         ax, %1
            call        kernel_panic
%endmacro

;---------------------------------------;
;   Hardware interrupts handlers        ;
;---------------------------------------;

%assign i 0x20
%rep 0x10
            DEFAULT_INTERRUPT %[i]
            %assign i i+1
%endrep

end_code    equ         $

;----------------------------------------------------------------------------;
;                               DATA SEGMENT                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;
section .data align=16
begin_data:

atixmsg:    db          "ATIX loading..."
atixmsgln   equ         $-atixmsg
hex_table:  db          "0123456789ABCDEF"
al_print    db          "XX"
haltmsg:    db          "ATIX: HALT PROCESSOR."
haltmsgln   equ         $-haltmsg

msg:
.debug_gdt  db          "Debug GDT:"
.debug_gdtln    equ     $ - .debug_gdt
.curr_csip  db          "Real mode CS:IP: "
.curr_csipln    equ     $ - .curr_csip
.colon      db          ":"
.gdt_desc  db          "GDT ACC BYTE: "
.gdt_descln equ        $ - .gdt_desc
.code_desc  db          "Code ACC BYTE: "
.code_descln equ        $ - .code_desc
.code_base  db          "Code base: "
.code_baseln equ        $ - .code_base
.code_limit  db          "Code limit: "
.code_limitln equ        $ - .code_limit
.code_desc_pos  db          "Code desc_pos: "
.code_desc_posln equ        $ - .code_desc_pos
.code_sel  db          "Code selector: "
.code_selln equ        $ - .code_sel
.data_desc  db          "Code ACC BYTE: "
.data_descln equ        $ - .data_desc
.data_sel  db          "Data selector: "
.data_selln equ        $ - .data_sel
.tss_desc  db          "TSS ACC BYTE: "
.tss_descln equ        $ - .tss_desc
.video_desc  db          "Video ACC BYTE: "
.video_descln equ        $ - .video_desc
.stack_desc db          "Stack ACC BYTE: "
.stack_descln equ        $ - .stack_desc
.idt_size       db      "IDT size: "
.idt_sizeln     equ     $-.idt_size
.pm         db          "Processor switched to the PROTECTED MODE."
.pmln       equ         $ - .pm

;-----------------------------------;
;       Kernel panic messages       ;
;-----------------------------------;
.kernel_panic   db      "Kernel PANIC."
.kernel_panicln equ     $-.kernel_panic
.nexc           db      "Exception number: "
.nexcln         equ     $-.nexc
.errcode        db      "Error code: "
.errcodeln      equ     $-.errcode
.oldcsip        db      "CS:IP = "
.oldcsipln      equ     $-.oldcsip
.oldf           db      "Flags = "
.oldfln         equ     $-.oldf
.res_exc        db      "Reserved exception."
.res_excln      equ     $-.res_exc
.hardware_int   db      "Unknown hardware interrupt."
.hardware_intln equ     $-.hardware_int
.other_int      db      "Unknown interrupt."
.other_intln    equ     $-.other_int
crsps:      db          0

;----------------------------------------------------------------------------;
;                         Global descripton table                            ;
;                                                                            ;
;----------------------------------------------------------------------------;
gdt:
.null_desc: DESCRIPTOR  0, 0, 0
gdt_base    equ         ATIX_SEG*0x10 + gdt
.code_desc: DESCRIPTOR  ATIX_CODE_BASE, (code_size-1), CODE_ACC_BYTE
.stack_desc:DESCRIPTOR  ATIX_STACK_BASE, (useful_size-1), STACK_ACC_BYTE
.data_desc: DESCRIPTOR  ATIX_CODE_BASE, (code_size+data_size-1),DATA_ACC_BYTE
.ktss_desc: dw          kernel_tss_size
            dw          kernel_tss_base
            db          0
            db          TSS_ACC_BYTE
            dw          0
.idt_desc:  dw          idt_size
            dw          idt
            db          0
            db          DATA_ACC_BYTE
            dw          0
.video_desc:DESCRIPTOR  0xb8000, SCRNRW*SCRNCL*2,DATA_ACC_BYTE
gdt_size    equ         $ - gdt
.gdt_desc:  dw          gdt_size-1
            dw          gdt_base                ; Lower 16 bits of base address
            db          0                       ; Higher 8 bits of the address
            db          0                       ; Set to 0 for i386
                                                ; compatibility.

code_sel    equ         ((.code_desc -  gdt)/DESC_SIZE)*0x08
data_sel    equ         .data_desc -  gdt
stack_sel   equ         .stack_desc -  gdt
video_sel   equ         .video_desc -  gdt

useful_size equ         code_size+data_size+tss_size
;----------------------------------------------------------------------------;
;                         Interrupt descriptor table                         ;
;                                                                            ;
;----------------------------------------------------------------------------;

idt:
;-----------------------------------;
;       Processor exceptions        ;
;-----------------------------------;
%assign i 0
%rep 0x20
idt_%[i]:
            dw          exc%[i]_h
            dw          code_sel
            db          0
            db          EXC_ACC_BYTE
            dw          0
            %assign i i+1
%endrep
;-----------------------------------;
;        Hardware interrupts        ;
;-----------------------------------;
%assign i 0x20
%rep 0x10
idt_%[i]:
            dw          int%[i]_h
            dw          code_sel
            db          0
            db          INT_ACC_BYTE
            dw          0
            %assign i i+1
%endrep


idt_size    equ         $-idt
idt_desc:
            dw          idt_size-1
            dw          idt+ATIX_SEG*0x10
            db          0
            db          0

end_data    equ         $

data_size   equ         end_data-begin_data

begin_tss   equ         $
kernel_tss  equ         $
tss:
.back_link_sel:
            resw        1
.sp_cpl0:   resw        1
.ss_cpl0:   resw        1
.sp_cpl1:   resw        1
.ss_cpl1:   resw        1
.sp_cpl2:   resw        1
.ss_cpl2:   resw        1
.registers: resw        14
.ldt_sel:   resw        1
end_kernel_tss  equ     $
kernel_tss_size equ     end_kernel_tss - kernel_tss
end_tss     equ         $
tss_size    equ         end_tss - begin_tss
kernel_tss_base equ     tss+ATIX_SEG*0x10

size        equ         code_size+data_size+tss_size
            times NBYTEPSEC*ATIX_NSEC-size db 0 ;empty sectors of the kernel

