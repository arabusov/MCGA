bits 16
section .text
org 0x200
start:  mov ax, 0xb800
        mov ds, ax
        mov ax, 0
        mov es, ax

        mov bx, 80*2;newline
        mov cx, blln+1
        mov bp, blmsg
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

halt:   hlt
        jmp halt
blmsg:  db  "Test BL message."
blln    equ $-blmsg
size    equ $-start
        times 512*3-size db 0 ;empty sectors

