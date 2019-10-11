bits 16
cpu 286

%include "atix.inc"
%include "fat12.inc"

code_size   equ         end_code - start
stack_size  equ         ATIX_STACK_OFFSET-code_size-data_size-ATIX_OFFSET

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
; Initialize segment registers:         ;
;---------------------------------------;

            mov         ax, ATIX_SEG    ; Set all segment registers
            mov         ds, ax
            mov         es, ax
            mov         ss, ax
            mov         sp, ATIX_STACK_OFFSET

            call        clrscr          ; Clear screen and print a "hello"
                                        ; message.
            mov         bp, atixmsg
            mov         cx, atixmsgln
            call        println

;---------------------------------------;
;           Halt processor              ;
;---------------------------------------;

            mov         bp, haltmsg
            mov         cx, haltmsgln
            call        println

atix_halt:
            hlt
            jmp         atix_halt

check_mode:
            smsw        ax
            and         ax, PM_BIT
            ret

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


;newline subroutine
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

end_code    equ         $

;----------------------------------------------------------------------------;
;                               DATA SEGMENT                                 ;
;                                                                            ;
;----------------------------------------------------------------------------;

begin_data  equ         $

atixmsg:    db          "ATIX loading..."
atixmsgln   equ         $-atixmsg
haltmsg     db          "ATIX: HALT PROCESSOR."
haltmsgln   equ         $-haltmsg
crsps:      db          0

;----------------------------------------------------------------------------;
;                         Global descripton table                            ;
;                                                                            ;
;----------------------------------------------------------------------------;

gdt:
            DESCRIPTOR  0, 0, 0, 0
.code_desc: DESCRIPTOR  ATIX_CODE_BASE, 0, code_size, CODE_ACC_BYTE
.stack_desc:DESCRIPTOR  ATIX_STACK_BASE,0,stack_size,STACK_ACC_BYTE
.data_desc: DESCRIPTOR  begin_data+ATIX_SEG*0x10,0,data_size,DATA_ACC_BYTE
.video_desc:DESCRIPTOR  0xb800,0,SCRNRW*SCRNCL*2,DATA_ACC_BYTE

code_sel    equ         ((.code_desc -  gdt)/DESC_SIZE)*0x04
data_sel    equ         ((.data_desc -  gdt)/DESC_SIZE)*0x04
stack_sel   equ         ((.stack_desc -  gdt)/DESC_SIZE)*0x04
video_sel   equ         ((.video_desc -  gdt)/DESC_SIZE)*0x04

;----------------------------------------------------------------------------;
;                         Interrupt descriptor table                         ;
;                                                                            ;
;----------------------------------------------------------------------------;

idt:
            %rep 0x100
            DESCRIPTOR 0, 0, 0, 0
            %endrep

data_size   equ         $-begin_data
size        equ         $-start
            times NBYTEPSEC*ATIX_NSEC-size db 0 ;empty sectors of the kernel

