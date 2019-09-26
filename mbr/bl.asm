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
        
        ;save disk number
        mov [disc],dl

        mov bx, SCRNCL;newline
        mov [es:crsps], bx
        mov cx, blln
        mov bp, blmsg
        call println

        call    find1part 
        call    printpartinfo
        call    printdiscinfo

        mov     bp,haltmsg
        mov     cx,haltmsgln
        call    println
halt:   hlt
        jmp halt



; subroutines
printdiscinfo:
        pusha
        mov     ah,0x08
        mov     dl,[disc]
        int     0x13
        mov     bx,BLCS
        mov     es,bx
        push    cx
        mov     cx, nsecmsgln
        mov     bp, nsecmsg
        call    print
        pop     ax
        push    ax
        call    printalln
        pop     cx
        popa
        ret
getfatsize:
        pusha
        push    es
        mov     ax, BLCS
        mov     es,ax

        pop     es
        popa
        ret

load1part:
        pusha
        push    es
        mov     ax, BLCS
        mov     es,ax
        mov     bx, tailptr
        mov     dl,[disc]
        mov     ah,0x02
        mov     al,1
        int     0x13
        jc      read_error
        cmp     al,1
        jne     read_error
        ; everything is fine: continue
        jmp     readexit

read_error:
        mov     bp,readerrmsg 
        mov     cx,readerrmsgln
        call    print
        push    ax
        mov     al,ah
        call    printalln
        pop     ax
haltr:  hlt
        jmp haltr
readexit:
        pop     es
        popa
        ret
printpartinfo:
        pusha
        push    ax
        push    cx
        mov     bp,stpartmsg
        mov     cx,stpartmsgln
        call    print
        call    printalln
        mov     bp,typepartmsg
        mov     cx,typepartmsgln
        call    print
        mov     al,ah
        call    printalln
        mov     bp,headpartmsg
        mov     cx,headpartmsgln
        call    print
        mov     al,dh
        call    printalln
        mov     bp,cspartmsg
        mov     cx,cspartmsgln
        call    print
        pop     ax ;cx with result of find1part -> ax
        push    ax
        mov     al,ah
        call    printal
        pop     ax
        call    printalln
        mov     cx,ax
        pop     ax
        popa
        ret

printalln:
        call    printal
        call    newline
        ret
println:
        pusha
        mov bx, [es:crsps]
        call    mvcurs
        shl bx,1
        call    print
        call    newline
        popa
        ret
newline:
        pusha
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
        push ds
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

find1part:
        push    ds

        mov     ax,0x07c0 ;yes, this is the mbr prgr
        mov     ds,ax

        mov     bx,PART1PTR
        mov     al,[bx]; status
        mov     ah,[bx+4]; type
        mov     dh,[bx+1]; head
        mov     cx,[bx+2];cyl/sector
        pop     ds
        ret


blmsg:  db  "Boot loader..."
blln    equ $-blmsg
alres   db  "XX"
disc    db  0
crsps   dw  0
stpartmsg       db  "Partition 1 status:  0x"
stpartmsgln     equ $-stpartmsg
typepartmsg     db  "Partition 1 type:    0x"
typepartmsgln   equ $-typepartmsg
headpartmsg     db  "Partition 1 head:    0x"
headpartmsgln   equ $-headpartmsg
cspartmsg       db  "Partition 1 cyl&sec: 0x"
cspartmsgln     equ $-cspartmsg
readerrmsg      db  "Read error. INT 13H: 0x"
readerrmsgln    equ $-readerrmsg
nsecmsg         db  "N Sectors / track:   0x"
nsecmsgln       equ $-nsecmsg
haltmsg         db  "HALT PROCESSOR."
haltmsgln       equ $-haltmsg
align 2
stckb:  times BLSTCKSIZE db 0
stcke:  equ $
tailptr:  equ stcke+2
size    equ $-start
        times 512*BLNSEC-size db 0 ;empty sectors

