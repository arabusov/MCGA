bits 16
cpu  286
section .text
%include "bl.inc"
%include "cfg.inc"
org BLIP
start: 
        mov ax, BLCS
        mov ds, ax
        mov ss, ax
        mov sp, stcke
        
        ;save disk number
        mov [disc],dl

        mov bx, SCRNCL;newline
        mov [crsps], bx
        mov cx, blln
        mov bp, blmsg
        call println
        mov     cx, csregmsgln
        mov     bp, csregmsg
        call    print
        mov     bx, cs
        mov     al, bh
        call    printal
        mov     al, bl
        call    printal
        mov     cx, ipregmsgln
        mov     bp, ipregmsg
        call    print
        mov     bx, start
get_ip:
        mov     al, bh
        call    printal
        mov     al, bl
        call    printalln

        call    find1part 
        call    printpartinfo
        call    printdiscinfo
        call    loadroot
        call    lsroot
        call    loadfat1
        ;call    test_fat
        mov     cx, 11
        mov     bp, blname
        call    println
        mov     si, blname
        call    test_file
        mov     cx, 11
        mov     bp, cfgname
        call    println
        mov     si, cfgname
        call    test_file

        call    load_cfg
        call    print_cfg
        call    parse_cfg
        mov     bp, kernelname
        mov     cx, 11
        call    println
        mov     bp,haltmsg
        mov     cx,haltmsgln
        call    println
halt:   hlt
        jmp halt
load_cfg:
        pusha
        mov     bx, cfg
        mov     si, cfgname
        call    read_file
        popa
        ret

parse:
        mov     bx, cfg
        mov     si, bx
        mov     cx, 0
.parse_loop:
        mov     al, [bx]
        cmp     al, EOF
        jz      .end_parse
        cmp     al, 0
        jz      .end_parse
        cmp     al, EOL
        jz      .line_ready
        cmp     al, '='
        jz      .eq_sign
        cmp     al, ' '
        jz      .continue
        inc     cl
.continue:
        inc     bx
        jmp     .parse_loop


.eq_sign:
        mov     dh, 0
        mov     al, cl
        call    printalln
        cmp     dl, cl
        jnz     .continue 
        mov     ax, ds
        mov     es, ax
        cld
        rep     cmpsb
        jnz     .continue
        mov     dh, 1
        inc     bx
        mov     si, bx
        mov     cx, 0
        jmp     .parse_loop


.continue_next_line:
        inc     bx
        mov     si, bx
        mov     cx, 0
        jmp     .parse_loop
.line_ready:
        cmp     dh, 0
        jz      .continue_next_line
.end_parse:
        ret

parse_cfg:
        pusha
        push    es
        mov     di, cfg_kernel
        mov     dl, cfg_kernelln
        call    parse

        cmp     dh, 0
        jz      .continue
        call    kernel_line
.continue:
        mov     di, cfg_address
        mov     dl, cfg_addressln
        call    parse

        cmp     dh, 0
        jz      .parse_cfg_end

.parse_cfg_end:
        pop     es
        popa
        ret

kernel_line:
        lea     di, [kernelname]
        mov     bx, 0
.name_copy:
        mov     al, [bx+si]
        cmp     al, '.'
        jz      .ex_copy
        mov     [bx+di], al
        inc     bx
        cmp     bx, 8
        jna     .name_copy
.ex_copy:
        lea     di, [kernelname+8]
        add     si, bx
        inc     si
        mov     cx, 3
        cld
        rep     movsb
        ret 

print_cfg:
        pusha
        mov     bx, cfg
        mov     cx, 0
        mov     bp, bx
print_cfg_loop:
        mov     al, [bx]
        cmp     al, EOF
        jz      end_print_cfg
        cmp     al, EOL
        jz      print_line
        cmp     al, 0
        jz      end_print_cfg
        inc     cx
        inc     bx
        jmp     print_cfg_loop
print_line:
        call    println
        inc     bx
        mov     bp, bx
        mov     cx, 0
        jmp     print_cfg_loop


end_print_cfg:
        mov     bp, eofmsg
        mov     cx, eofln
        call    println
        popa
        ret
; subroutines
printdiscinfo:
        pusha
        mov     ah,0x08
        mov     dl,[disc]
        int     0x13
        mov     bp,BLCS
        mov     es,bp
        push    cx
        mov     cx,drtypemsgln
        mov     bp,drtypemsg
        call    print
        mov     al,bl
        call    printalln
        mov     cx, nsecmsgln
        mov     bp, nsecmsg
        call    print
        pop     ax
        push    ax
        and     ax,0x3f; [5 -- 0] bits
        mov     [maxsec],al
        mov     byte [maxsec+1], 0
        call    printalln
        mov     cx, ncylmsgln
        mov     bp, ncylmsg
        call    print
        pop     ax
        push    ax
        shr     al,6
        mov     [maxcyl+1],al
        call    printal
        mov     al,ah
        mov     [maxcyl],al
        call    printalln
        mov     cx,nheadmsgln
        mov     bp,nheadmsg
        call    print
        mov     al,dh
        mov     [maxhead],al
        call    printalln

        pop     cx
        popa
        ret

;----------------------------------------------------------------------------;
;                               LBA -> CHS                                   ;
;                                                                            ;
; Arguments:                                                                 ;
;     1. AX --- LBA address.                                                 ;
;     2. maxsec, maxhead, and maxcyl are initialized.                        ;
; Result:                                                                    ;
;     1. CX --- Sector and Cylinder in BIOS format                           ;
;         [15 -- cyl [7-0] -- 8 | 7 -- cyl [8--9] -- 6 5 -- sec [5--0] -- 0] ;
;     2. DH --- Head.                                                        ;
;     3. AX --- error code.                                                  ;
;                                                                            ;
;----------------------------------------------------------------------------;

lba2chs:
        inc     al
                                             ; AX -- sector
        xor     dh, dh
        xor     cx, cx
lba2chs_main_loop:
        cmp     ax, [maxsec]
        jna     lba2chs_return

        sub     ax, [maxsec]
        inc     dh

        cmp     dh, [maxhead]
        jna     lba2chs_main_loop

        sub     dh, [maxhead]
        dec     dh
        inc     cx

        cmp     cx, [maxcyl]
        jna     lba2chs_main_loop

                                            ; CX > maxcyl. Error
        mov     al, 0x01                    ; Error flag
        mov     ah, BL_ERR_CYL_OUT_OF_RANGE
        ret

lba2chs_return:
        push    bx
        mov     bx, cx
        mov     cx, ax
        mov     ch, bl
        shl     bh, 6
        or      cl, bh
        pop     bx
        xor     ax, ax
        ret

loadfat1:
        pusha
        mov     bx,fat1
        mov     ax,1
        mov     cx,FATSIZE
        call    loadfromdisc
        popa
        ret

test_fat:
        pusha
        mov     cx, 21
test_fat_loop:
        mov     ax, cx
        call    fat_next_cluster
        push    ax
        mov     al, ah
        call    printal
        pop     ax
        call    printalln
        loop    test_fat_loop


        popa
        ret

fat_next_cluster:
                        ; ax -- current cluster
        cmp     ax, 0xffb
        jae     no_next_cluster

        ; ax is an index, but cell size is 12-bits,
        ; so 3*ax/2 points on a byte in the FAT.
        push    bx
        mov     bx, ax
        shr     ax, 1           ; div by 2
        push    cx
        mov     cx, 3
        mul     cx
        pop     cx
        test    bx, 1
        jz      even_case
odd_case:
        ; 22 32 33 44 54 55
        ; 03 40 00 05 60 00 values
        ; 2  3  4  5  6  7  bytes
        mov     bx, ax
        add     bx, fat1
        mov     al, [bx+1]
        mov     ah, [bx+2]
        shr     ax, 4
        jmp     ret_next_cluster
even_case:
        mov     bx, ax
        add     bx, fat1
        mov     al, [bx]
        mov     ah, [bx+1]
        and     ah, 0x0f
ret_next_cluster:
        pop     bx

no_next_cluster:
        ret
loadroot:
        pusha
        mov     bx,root
        mov     ax,1+2*FATSIZE
        mov     cx,ROOTSIZE
        call    loadfromdisc
        popa
        ret

cmpstr:
        push    cx
        mov     ax, 0
        mov     cx, 11 ; 8.3
        cld
        rep     cmpsb
        jnz     cmpstr_end
        mov     ax, 1
cmpstr_end:
        pop     cx
        ret

file_find:
        push    es
        push    di
        push    bx
        push    cx

        mov     ax, BLCS
        mov     es, ax
        mov     bx, root
        mov     cx, ROOTSIZE*NBYTEPSEC/32
        push    si
file_find_loop:
        pop     si
        push    si
        lea     di, [bx]
        call    cmpstr
        add     bx, 32
        cmp     ax, 1
        jz      file_found
        loop    file_find_loop
        mov     ax, 0x00
        jmp     end_file_find

file_found:
        sub     bx, 32
        mov     ax, [bx+32-4-2]
end_file_find:
        pop     si
        pop     cx
        pop     bx
        pop     di
        pop     es
        ret
test_file:
        pusha
        call   file_find
test_file_loop:
        cmp     ax, 0
        jz      end_test_file

        cmp     ax, 0x0fff
        jz      end_test_file

        cmp     ax, 0x0ff0
        jz      end_test_file
        push    ax
        mov     al, ah
        call    printal
        pop     ax
        call    printalln
        call    fat_next_cluster
        jmp     test_file_loop

end_test_file:
        popa
        ret

read_file:
        pusha
        call    file_find
read_file_loop:
        cmp     ax, 0
        jz      end_read_file

        cmp     ax, 0x0fff
        jz      end_test_file

        cmp     ax, 0x0ff0
        jz      end_test_file
        dec     ax
%if NSECPCLU > 1
        mov     cx, NSECPCLU
        mul     cx
%endif
        add     ax, DATA_AREA
        mov     cx, 1
%rep    NSECPCLU
        call    loadfromdisc
        add     bx, NBYTEPSEC
        inc     ax
%endrep
        call    fat_next_cluster
end_read_file:
        popa
        ret
lsroot:
        pusha
        mov     bp, lsmsg
        mov     cx, lsmsgln
        call    println
        mov     cx, ROOTSIZE*NBYTEPSEC/32 ; 32 bytes per a record
        mov     bx, root
lsroot_loop:
        mov     ax, [bx]
        cmp     ax, 0
        jz      lsroot_end
        mov     bp, bx
        push    cx
        mov     cx, 8
        call    print
        add     bx, 8
        mov     bp, bx
        mov     cx, 3
        call    println
        add     bx, 32-8
        pop     cx


        loop    lsroot_loop


lsroot_end:

        popa
        ret

loadfromdisc:
        pusha
        push    es

        mov     dx, BLCS
        mov     es,dx
        mov     dl,[disc]
        mov     word [number_of_attempts], 1
read_loop:
        push    cx
        push    ax          ; <-- ax -- LBA addr
        ;mov     al, ah
        ;call    printal
        ;pop     ax
        ;push    ax          ; <-- still LBA addr
        ;call    printal
        call    lba2chs
        ;push    ax          ; CHS result, then LBA addr
        ;mov     al, cl
        ;call    printal
        ;mov     al, dh
        ;call    printal
        ;mov     al, ch
        ;call    printalln

        ;pop     ax          ; ax = CHS result, LBA addr in stack
        cmp     al, 0
        jnz     read_error
read_twice:
        mov     ax, 0x0201
        int     0x13

        
        jc      second_attempt
        cmp     al,1
        jne     read_error
        pop     ax          ; get LBA addr from stack
        inc     ax
        add     bx, NBYTEPSEC
        mov     word [number_of_attempts], 1
        pop     cx
        loop    read_loop
        jmp     readexit
second_attempt:
        push    dx          ; dx, LBA addr
        mov     dx, [number_of_attempts]
        cmp     dx, 1
        jne     read_error
        mov     word [number_of_attempts], 2
        pop     dx          ; LBA addr in stac
        mov     ah,0
        int     0x13
        jc      read_error

        pop     ax
        push    ax          ;LBA addr in stack
        call    lba2chs
        jmp     read_twice


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
        mov bx, [crsps]
        call    mvcurs
        shl bx,1
        call    print
        call    newline
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
        pusha
        push    ds

        mov     ax,0x07c0 ;yes, this is the mbr prgr
        mov     ds,ax

        mov     bx,PART1PTR
        mov     al,[bx]; status
        mov     ah,[bx+4]; type
        mov     dh,[bx+1]; head
        mov     cx,[bx+2];cyl/sector
        pop     ds
        popa
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
nsecmsg         db  "Last sector:         0x"
nsecmsgln       equ $-nsecmsg
ncylmsg         db  "Last cylinder:       0x"
ncylmsgln       equ $-ncylmsg
nheadmsg        db  "Last head:           0x"
nheadmsgln      equ $-nheadmsg
drtypemsg       db  "Drive type:          0x"
drtypemsgln     equ $-drtypemsg
lsmsg           db  "List of files in root directory:"
lsmsgln         equ $-lsmsg
haltmsg         db  "HALT PROCESSOR."
haltmsgln       equ $-haltmsg
csregmsg        db  "CS : 0x"
csregmsgln      equ $-csregmsg
ipregmsg        db  ", IP : 0x"
ipregmsgln      equ $-ipregmsg
cfg_kernel      db  "kernel"
cfg_kernelln   equ $-cfg_kernel
kernelname      times 11 db " "
cfg_address      db  "address"
cfg_addressln    equ $-cfg_address
cfgname         db  "CONFIG  "
cfgext          db  "INI"
blname          db  "BL      "
blext           db  "COM"
eofmsg          db  "EOF"
eofln           equ $-eofmsg
maxsec          dw  0
maxhead         db  0
maxcyl          dw  0
number_of_attempts dw 0
align 2
stckb:  times BLSTCKSIZE db 0
stcke:  equ $
fat1    equ stcke+2
root    equ fat1+FATSIZE*NBYTEPSEC
cfg     equ root+ROOTSIZE*NBYTEPSEC
size    equ $-start
        times NBYTEPSEC*BLNSEC-size db 0 ;empty sectors of the bootloader
