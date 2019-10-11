bits 16
cpu 286

%include "atix.inc"
%include "fat12.inc"
section .text
org ATIX_OFFSET
start:
            mov         ax, ATIX_SEG    ; Set all segment registers
            mov         ds, ax
            mov         es, ax
            mov         ss, ax
            mov         sp, 0xffff

            call        clrscr          ; Clear screen and print a "hello"
                                        ; message.
            mov         bp, atixmsg
            mov         cx, atixmsgln
            call        print

atix_halt:
            hlt
            jmp         atix_halt

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
            mov         word [bx], 0x0200
            loop        .loop

            mov         bx, 0
            call        mvcurs

            pop         ds
            pop         cx
            pop         bx
            ret

;----------------------------------------------------------------------------;
;                             Print routine                                  ;
;                                                                            ;
;----------------------------------------------------------------------------;

print:  
            pusha
            push        ds
            push        es
            mov         ax, ATIX_SEG
            mov     es, ax
            cmp     cx,0
            jz      endprn
            mov     bx,[es:crsps]
            shl     bx,1
            mov ax, SCRSEG
            mov ds, ax
            mov ah, 0x02
get_symbol:
            mov al, [es:bp]
            cmp     al, 13 ;newline
            jnz     check_10
            push    bx
            shr     bx,1
            mov     [es:crsps],bx
            call    mvcurs
            call    newline
            pop     bx
            inc     bp
            dec     cx
            jz      endprn
            jmp     get_symbol
check_10:
            cmp     al,10
            jnz     contprint1
            push    ax
            mov     ax,bx
            mov     bl,SCRNCL
            div     bl
            mov     bl,SCRNCL
            mul     bl
            mov     bx,ax
            pop     ax
            inc     bp
            dec     cx
            jz      endprn
            jmp     get_symbol

contprint1:
            cmp bx, SCRNCL*SCRNRW*2
            jb  contprint2
            call    nl
            mov bx,SCRNCL*(SCRNRW-1)*2
            push bx
            shr bx,1
            call    mvcurs
            pop bx
contprint2:
            mov [bx], ax
            add bx, 2
            inc bp
            loop get_symbol

endprn:
            shr bx,1
            call mvcurs
            pop es
            pop ds
            popa
            ret


mvcurs:
            pusha
            push    ds
            mov     ax, ATIX_SEG
            mov     ds, ax
            mov [crsps], bx ;save the position
            mov dx, 0x03d4
            mov al, 0x0f
            out dx, al

            inc dl
            mov al, bl
            out dx, al

            dec dl
            mov al, 0x0e
            out dx, al

            inc dl
            mov al, bh
            out dx, al
            pop     ds
            popa
            ret


;newline subroutine
nl:
            pusha
            push    es
            push    ds

            mov     ax, SCRSEG
            mov     ds, ax
            mov     es, ax
            mov     di, 0x00
            mov     si, SCRNCL*2
            mov     cx, SCRNCL*(SCRNRW-1)*2
            cld
            rep
            movsb
            mov     di, SCRNCL*(SCRNRW-1)*2
            mov     cx, SCRNCL
            mov     ax, 0x0200
clearln:
            mov     [di],ax
            add     di,2
            loop    clearln

            pop ds
            pop es
            popa
            ret
newline:
        pusha
        mov ax, [crsps]
        mov bl,SCRNCL
        div bl
        cmp al, SCRNRW
        je  cnl
        add al,1
        mov ah,0
        mov bx,SCRNCL
        mul bl
        mov bx,ax
        call    mvcurs
        jmp endprint

cnl:
        call    nl
        mov bx,SCRNCL*(SCRNRW-1)
        call    mvcurs
endprint:
        popa
        ret

atixmsg:    db          "ATIX loading..."
atixmsgln   equ         $-atixmsg
colon:      db          ":"
crsps:      db          0
size    equ $-start
            times NBYTEPSEC*ATIX_NSEC-size db 0 ;empty sectors of the kernel
