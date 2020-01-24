#!/bin/sh

PROGRAM="mpi_test"
ARGUMENTI="$@" # Argumenti, ki jih dobimo iz xRSL (atribut "arguments")

# 1. Prevajanje
mpicc $PROGRAM.c -o $PROGRAM

# 2. Zagon programa
mpirun -np 2 ${PWD}/$PROGRAM $ARGUMENTI

# 3. Koncno stanje programa
exitcode=$?
echo Program je koncal s kodo $exitcode.

exit $exitcode
