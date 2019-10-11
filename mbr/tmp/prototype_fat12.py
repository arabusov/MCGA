#!/usr/bin/python3
def pair (x, y):
    return (x % 0x100, (x // 0x100) + (y % 0x10)*0x10,
        (y // 0x10))

prg_lens = [10, 1]
def gen_fat12_rawtable1 (prg_lens):
    fat12_table=[]
    current_sector = 2
    for i in prg_lens:
        for j in range (i-1):
            current_sector = current_sector + 1
            fat12_table.append (current_sector)
        current_sector = current_sector + 1
        fat12_table.append (0xfff)
    fat12_raw = []
    for i in range (0, len (fat12_table), 2):
        triple = pair (fat12_table[i], fat12_table[i+1])
        fat12_raw.append (triple[0])
        fat12_raw.append (triple[1])
        fat12_raw.append (triple[2])
    if len(fat12_table) % 2 == 1:
        triple = pair (fat12_table[-1], 0x000)
        fat12_raw.append (triple[0])
        fat12_raw.append (triple[1])
        fat12_raw.append (triple[2])
    return fat12_raw

def gen_fat12_rawtable2 (prg_lens):
    fat12_raw = []
    current_sector_base = 2
    current_sector=current_sector_base
    current_prg=0 #num from 0
    current_sum = 0
    while current_prg < (len(prg_lens) ):
        current_sum = current_sum + prg_lens [current_prg]
        while current_sector < (current_sector_base+current_sum-2):
            triple=pair (current_sector+1, current_sector+2)
            current_sector = current_sector + 2
            fat12_raw.append (triple[0])
            fat12_raw.append (triple[1])
            fat12_raw.append (triple[2])
        triple=()
        # -3 + 2 == -1
        if (current_sector == current_sector_base+current_sum-1):
            if current_prg < (len(prg_lens) -1):
                if prg_lens[current_prg+1] >= 2:
                    triple=pair (0xfff,current_sector+2)
                    current_prg = current_prg + 1
                else: #prg_lens [current_prg+1] == 1:
                    triple=pair (0xfff, 0xfff)
                    current_sum = current_sum + prg_lens [current_prg+1]
                    current_prg = current_prg+2
            else:
                triple=pair (0xfff, 0)
                current_prg = current_prg+1
        # -4 +2 == -2
        else:
            triple=pair (current_sector+1, 0xfff)
            current_prg = current_prg+1
        fat12_raw.append (triple[0])
        fat12_raw.append (triple[1])
        fat12_raw.append (triple[2])
        current_sector = current_sector + 2
    return fat12_raw
print (prg_lens)
for i,val in enumerate(gen_fat12_rawtable2 (prg_lens)):
    print ("db " + str(hex (val)))
