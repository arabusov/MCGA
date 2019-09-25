bits 16
section .text
org 7c00h
start: 
        push    dx
        mov ax, 0b800h
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

        ; start to read next sectors
        pop dx
        mov ax, 0x0100
        mov es, ax
        mov bx, 0x0000 ; relative address for the BL
        mov ah, 0x02
        mov al, 3 ;n sectors
        mov ch, 0 ;cylinder
        mov cl, 2 ;sector, numbering from 1
        mov dh, 0 ;head
                  ; dl is initialized
        int 0x13
        jmp 0x0000:0x1000 ; long jump to the BL
halt:   hlt
        jmp halt
mbrmsg: db  "Test MBR message."
mbrln   equ $-mbrmsg
size    equ $-start
        times 510-size db 0
        dw      0aa55h

