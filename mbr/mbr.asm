bits 16
section .text
org 7c00h
start:  mov ax, 0b800h
        mov ds, ax
        mov ax, 0
        mov es, ax
        mov bx, 80*25*2+2
        mov ax, 0200h
clear:  mov [bx-2], ax
        sub bx, 2
        jnz clear

        mov bx, 0
        mov cx, mbrln+1
        mov bp, mbrmsg
        mov al, [es:bp]
        mov ah, 02h
loo:    mov [bx], ax
        add bx, 2
        inc bp
        mov al, [es:bp]
        loop loo
        shr bx,1
        dec bx

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

        hlt
mbrmsg: db  "Test MBR message."
mbrln   equ $-mbrmsg
size    equ $-start
        times 510-size db 0
        dw      0aa55h

