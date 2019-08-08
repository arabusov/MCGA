#!/bin/bash

touch debug.out
xterm -e tail -f debug.out &
debug_pid=$!
./machine
echo Closing debug.out...
sleep 2
kill $debug_pid
