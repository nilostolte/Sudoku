# Sudoku solver - Zig Implementation

## Solving Sudoku Grids on Windows 64

See documentation on how to use this program [here](https://github.com/nilostolte/Sudoku/tree/main/documentation).

## Optimizations done in this version

I have done several different optimizations in Zig. Some are either not possible, either not portable
in C. Many of them may be available on gcc but not in other compilers. On the other hand, every
optimization made here in the Zig version is portable, although some may not generate the 
most optimal performance in platforms different than X64.

### Using a linear grid

In Zig the grid matrix is given linearly by an array containing the 81 elements of the grid stored 
line by line contiguously:

``` Zig
    var grid = [_]u8{0} ** 81;        // Sudoku grid stored linearly here
```

This configuration increases cache coherency and avoids indirections to access the elements via pointers
as it's usually done in matrices and as it was also done in previous versions of this Zig code. The 
linear storage doesn't come for free, since it implies additional operations in the `solve` function to be
able to cope with this configuration.

The most notable is to maintain not only the line and column of an element (`j` and `i` variables), but 
also its index (`index` variable) in the linear grid.

Additional operations are needed to recover `index` whenever backtracking, by calculating it
with the previous line and column values popped from the stack. Here one needs to multiply `i` (the 
current line) by 9, to jump over the previous lines, and add `j`, the current column:

``` Zig
    index = @shlExact(i,3) + i + j;
```

Since backtracking occurs less often than other parts of the loop, these extra operations
don't impact the performance in a noticeable way.

The most frequent operation impacting the linear grid configuration is an extra addition to
increment `index`, besides the usual `j` incrementation at the end of the loop just before
testing a line change and end of the loop:

``` Zig
      index += 1;                         // advance to the next position in grid
      j += 1;                             // advance to the next column
```

Fortunately, the time spent in the extra operations didn't overlap the time gained with the
linear grid storage. Less indirections and more coherency when accessing the elements one after
the other in sequence as done here highly justified the cost of extra operations. It's clear that 
the less one needs to use values stored in memory the better the solver performs. Focusing on
that unveiled quite a few surprises after calculating values dynamically instead of accessing the
calculated values in memory.

### Calculating the grid element value from bit representation using @popcount

Each grid element value (0 to 9) is represented in binary as shown in the table below to speed up 
occupation sets checking.

| Element Value | Binary Representation | Hexadecimal | Decimal |
| :-----------: | :-------------------: | :---------: | :-----: |
| 0             | **000000000**         | 0x000       | 0       |
| 1             | **000000001**         | 0x001       | 1       |
| 2             | **000000010**         | 0x002       | 2       |
| 3             | **000000100**         | 0x004       | 4       |
| 4             | **000001000**         | 0x008       | 8       |
| 5             | **000010000**         | 0x010       | 16      |
| 6             | **000100000**         | 0x020       | 32      |
| 7             | **001000000**         | 0x040       | 64      |
| 8             | **010000000**         | 0x080       | 128     |
| 9             | **100000000**         | 0x100       | 256     |

In practice, one never uses zero because in Sudoku zero represents an empty element, an element not yet
filled with an estimated value by the solver. All estimated values are then between 1 and 9.

It's easy to convert a value `n`, where:

``` Zig
    n ∈ {1, 2, 3, 4, 5, 6, 7, 8, 9} 
```
If `code` is the binary representation of `n`, one can calculate `code` in this way:

``` Zig
    code = 1 << (n-1)
```

But it's not simple to obtain `n` from `code`, unless using popcount assembly instruction.

Since popcount instruction counts the numbers of ones in an integer binary value, one can calculate `n` in 
this way in Zig:

``` Zig
    n = @​popCount(code - 1) + 1
```

Substituting this code in the Zig version of the Sudoku solver produced a noticeable optimization. The ​popCount built-in actually generates a single Assembler instruction as shown here:

<p align="center">
    <img src="https://github.com/user-attachments/assets/ba6d2502-1c3b-4276-83cd-6f06a3476bcf" width="400">
</p>

### Actually calculating a division by 3 instead of using tables.

This was one of the most surprising optimizations of them all. In Sudoku one needs to calculate
in which 3x3 subgrid (that I called a "cell," but in Sudoku, cells generally refer to any of its 
81 grid elements) an element belongs to check if an estimated value for this element is already
used somewhere in its subgrid.

This is normally done by first calculating the following two integer truncating divisions:

``` Zig
    @divTrunc(i, 3)
    @divTrunc(j, 3)
```

Initially, I was doing this using a table, since I estimated that divisions would be too slow. 

But I decided to try doing the division explicitly as shown above, and I was quite surprised to
see that a significant speed up was obtained. That puzzled me and it triggered me to investigate
what was going on under the hood.

What I found was that the Assembler code produced was actually only doing an integer multiplication
followed by a shift operators as shown below.

<p align="center">
    <img src="https://github.com/user-attachments/assets/2396d038-f5ff-4f23-a8f5-abe180350a62" width="400">
</p>

I kind of understood that it was multiplying the value by a fixed point notation for ⅓, but to me
that could never result into an exact integer number corresponding to the quotient. Well, it turns
out it can.

The math behind is called Modular Arithmetic. I didn't dive in depth, but the demonstration in 
[this site](https://www.pagetable.com/?p=23) is pretty clear, although I just browsed through. It's 
indeed basically a fixed point notation in binary (0xAAAB in the code corresponds to 
~0.3333 but shifted left in binary), but the arithmetic, however, is not approximate as one would 
normally assume. It's demonstrable exact.

### Use of prefetch

Prefetch is a very interesting resource for increasing memory cache coherency. One can't use in many 
places in the same context. In this code I used it before entering the loop and at the end of the loop
to keep `grid[index]` in the cache memory. I just tewweked some values and it actually produced faster
executions.
