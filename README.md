# Make pure C Great Again
## Prerequirements
For using LASM (LASM assembler) you need to install _mit-scheme_

To test mbr you have to install
  - nasm
  - qemu (qemu-system-i386)

## Testing MBR program
```bash
cd mbr
make run
```

Enjoy!

## Compile Turing machine
```
make
```
## Usage
First, we want to "compile" assembler code for the machine:
```
cd lasm
./asm.sh helloworld.asm helloworld
```
For debugging I added a hexdump output to the stdout, but the
binary file should be _helloworld_. Then you can try to run the
machine
```
cd .. #suppose you was in lasm directory befor
#make #if you haven't compiled the machine yet
./run.sh lasm/helloworld
```
__ENJOY!__

