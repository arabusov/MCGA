#!/bin/bash
FILE=$1
if [[ $FILE == "" ]]; then
    echo "No input file."
    exit -1
else
    echo "1"
    cp $FILE source.asm
    echo "2"
    #scheme < lasm.scm
    scheme --quiet < lasm.scm
    echo "3"
    rm source.asm
    echo "4"
    hexdump a.out
    echo "5"
    if [[ $2 == "" ]]; then
        echo Done.
    else
        cp a.out $2
        rm a.out
    fi
fi
