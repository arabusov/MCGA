%include "bl.inc"
bits 16
section .text
org 7c00h
start: 
        ;save disc info
        push    dx
        ; init screen address
        mov ax, 0b800h
        mov ds, ax
        ; init data segment
        mov ax, 0
        mov es, ax
        ; parse disc info
        test    dl,0x80
        jnz     disc_c
        add     dl, 'A'
        jmp     save_l
disc_c: and     dl,0x7f ; or even 0x0f
        add     dl, 'C'
save_l: mov     [es:disc_p],dl
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

        ; start to read next sectors
        pop dx
        mov ax, BLCS
        mov es, ax
        mov bx, BLIP ; relative address for the BL
        mov ah, 0x02
        mov al, BLNSEC ;n sectors
        mov ch, 0 ;cylinder
        mov cl, 2 ;sector, numbering from 1
        mov dh, 0 ;head
                  ; dl is initialized
        int 0x13
        jmp BLCS:BLIP; long jump to the BL
halt:   hlt
        jmp halt
mbrmsg: db  "MBR loaded from disc X"
disc_p  equ $-1
        db  ". Start boot loader..."
mbrln   equ $-mbrmsg
size    equ $-start
        times 510-size db 0
        dw      0aa55h

