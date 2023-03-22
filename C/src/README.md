
# Sudoku Solution in C Programming Language

This directory contains the C source code for the application to solve arbitrary Sudoku grids. This documentation is to compile
this source code to generate the executable file, not to run the executable. The documentation to run the program is 
[here](https://github.com/nilostolte/Sudoku/tree/main/C/doc).

## Instructions to compile the source code

Use separate compilation for [grid.c](https://github.com/nilostolte/Sudoku/blob/main/C/src/grid.c) and 
[main.c](https://github.com/nilostolte/Sudoku/blob/main/C/src/main.c) by executing the makefile 
[s](https://github.com/nilostolte/Sudoku/blob/main/C/src/s) in a command window positioned where these files were copied to, as follows:

```
make -f s
```

Or use [ninja](https://ninja-build.org/) build system with the file [build.ninja](https://github.com/nilostolte/Sudoku/blob/main/C/src/build.ninja),
by calling ninja in a command window positioned where these files were copied to, as follows:

```
ninja
```
