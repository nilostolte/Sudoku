
# Solving Sudoku Grids with the C or Zig Executable

The executable after compiling the Zig or C implementation works differently than in Java. Here, the
grid must be supplied by an 81 characters long string, containing the grid's digits one by one, line 
by line in a single row.

## Calling the program

The supplied [Zig executable](Zig/sudoku.exe) or [C executable](C/bin/sudoku.exe), which work on 
Windows 64, or the executable produced compiling thes source code in another platform, should be called 
in the following way in a shell window located where the program is:

```
./sudoku .1.9..74....8....3.7..2.69...4.3.2.....6.2.....8.1.3...81.7..3.3....8....69..3.2.
```

Or

```
./sudoku 010900740000800003070020690004030200000602000008010300081070030300008000069003020
```

Both notations are accepted.

## Output

The output of the program shows the initial unsolved grid and the corresponding solved grid, followed by 
the time to solve the grid in miliseconds:

```
===================
    Input Grid
===================
| |1| |9| | |7|4| |
| | | |8| | | | |3|
| |7| | |2| |6|9| |
| | |4| |3| |2| | |
| | | |6| |2| | | |
| | |8| |1| |3| | |
| |8|1| |7| | |3| |
|3| | | | |8| | | |
| |6|9| | |3| |2| |

===================
     Solution
===================
|8|1|3|9|6|5|7|4|2|
|2|9|6|8|4|7|1|5|3|
|4|7|5|3|2|1|6|9|8|
|1|5|4|7|3|9|2|8|6|
|9|3|7|6|8|2|4|1|5|
|6|2|8|5|1|4|3|7|9|
|5|8|1|2|7|6|9|3|4|
|3|4|2|1|9|8|5|6|7|
|7|6|9|4|5|3|8|2|1|

time in miliseconds: 0.81980
```
