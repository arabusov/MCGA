#!/bin/bash
FILE=$1
if [[ $FILE == "" ]]; then
    echo "No input file."
    exit -1
else
    cp $FILE source.asm
    scheme --quiet < lasm.scm
    rm source.asm
    hexdump a.out
    if [[ $2 == "" ]]; then
        echo Done.
    else
        cp a.out $2
        rm a.out
    fi
fi
