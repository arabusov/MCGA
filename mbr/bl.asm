bits 16
section .text
%include "bl.inc"
org BLIP
start:  
        mov ax, BLCS
        mov ds, ax ;ds==cs
        mov ax, BLCS
        mov es, ax ;es==cs
        mov ax, BLCS
        mov ss, ax
        mov sp, stcke

        mov bx, SCRNCL;newline
        mov [es:crsps], bx
        mov cx, blln
        mov bp, blmsg
        call println

        mov cx,0x1f
many:
        mov al,cl
        call    printal
        push cx
        mov cx,cntmsgln
        mov bp,cntmsg
        call println
        pop cx
        loop many



halt:   hlt
        jmp halt

; subroutines
println:
        pusha
        mov bx, [es:crsps]
        call    mvcurs
        shl bx,1
        call    print
        mov ax, [es:crsps]
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
printal:
        pusha
        mov     ah, al
        and     ah,0x0f
        shr     al,4
        cmp     al, 0x0a
        jae     adda1
        add     al, '0'
        jmp     contin1
adda1:  add     al, 'A'
        sub     al, 0x0a
contin1:
        cmp     ah, 0x0a
        jae     adda2
        add     ah, '0'
        jmp     contin2
adda2:  add     ah, 'A'
        sub     ah, 0x0a
contin2:
        mov     [es:alres], ax
        mov     cx, 2
        mov     bp,alres
        call    print
        popa
        ret

print:  
        pusha
        mov     bx,[es:crsps]
        shl     bx,1
        push ds
        mov ax, SCRSEG
        mov ds, ax
        mov al, [es:bp]
        mov ah, 0x02
loo:    cmp bx, SCRNCL*SCRNRW*2
        jb  contprint
        call    nl
        mov bx,SCRNCL*(SCRNRW-1)*2
        push bx
        shr bx,1
        call    mvcurs
        pop bx
contprint:
        mov [bx], ax
        add bx, 2
        inc bp
        mov al, [es:bp]
        loop loo
        shr bx,1
        call mvcurs
        pop ds
        popa
        ret


mvcurs:
        pusha
        mov [es:crsps], bx ;save the position
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



blmsg:  db  "Boot loader..."
blln    equ $-blmsg
alres   db  "XX"
crsps   dw  0
cntmsg  db  " -- counter."
cntmsgln equ $-cntmsg
align 2
stckb:  times BLSTCKSIZE db 0
stcke:  equ $
size    equ $-start
        times 512*BLNSEC-size db 0 ;empty sectors

