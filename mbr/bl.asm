bits 16
section .text
%include "bl.inc"
org BLIP
start:  mov ax, 0xb800
        mov ds, ax
        mov ax, BLCS
        mov es, ax ;es==cs

        mov bx, 80*2;newline
        mov cx, blln
        mov bp, blmsg
        call print

halt:   hlt
        jmp halt
print:  mov al, [es:bp]
        mov ah, 02h
loo:    mov [bx], ax
        add bx, 2
        inc bp
        mov al, [es:bp]
        loop loo
        shr bx,1

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
        ret
blmsg:  db  "Boot loader: HALT."
blln    equ $-blmsg
size    equ $-start
        times 512*BLNSEC-size db 0 ;empty sectors

