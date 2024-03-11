<img src="https://github.com/nilostolte/Sudoku/assets/80269251/ef41fe74-1b8b-415a-bab4-a65fd98ce03e" width="512" height="512"><br>

# Sudoku
Simple 9x9 Sudoku brute force solver with intrinsic parallel candidate set processing thanks to the use of bit representation for the 1-9 digits as well as bitwise operations allowing to test all the candidates at once.

It can be upgraded for 16x16 or 25x25 grids.

The algorithm was implemented in [Java](https://github.com/nilostolte/Sudoku/blob/main/src), in 
[C](https://github.com/nilostolte/Sudoku/tree/main/C/src), as well as in [Zig](https://github.com/nilostolte/Sudoku/tree/main/Zig). The description below
concerns the Java implementation, even though, the [C implementation](https://github.com/nilostolte/Sudoku/tree/main/C/src) 
is quite similar, but without classes. [Zig implementation](https://github.com/nilostolte/Sudoku/tree/main/Zig) is similar to C's but with an OOP style stack.

The [Windows 64 executable supplied](https://github.com/nilostolte/Sudoku/blob/main/C/bin/sudoku.exe) can be used to 
solve arbitrary grids as decribed in the [documentation](https://github.com/nilostolte/Sudoku/tree/main/C/doc).

Updates done here and corresponding code are reported on Twitter below [this tweet](https://twitter.com/nilostolte/status/1633804599730622469). Please
follow me on Twitter for updates.

## Grid

This is the [class](https://github.com/nilostolte/Sudoku/blob/main/src/Grid.java) containing the grid to be solved. 

### Input 

The grid can be initialized using a 9x9 matrix of type `char[][]` or through a linear string containing all the elements, representating 
empty elements as 0, both given line by line. The `char[][]` is the unique input, however, and it must exist before being able to use
any other input format. Even though the 9x9 matrix contains characters (it's a `char[][]`), the digits are not represented as ASCII or Unicode
characters but rather as integers. In other words, the character '0' is actually represented by 0, and so forth.

In the string input format the string is just copied over the existing input `char[][]` matrix using the static function `set`. This string uses 
ASCII representation for the digits which are converted to integers by the function `set`.

An additional representation is possible, as illustrated in [Main.java](https://github.com/nilostolte/Sudoku/blob/main/src/Main.java), by 
representing the charcater '0' with the character '.' in the string. In this case one adds `.replace('.','0')` at the end of the string as shown.

Both string input formats are common representations of Sudoku grids on the web.

### Data Structures

The main data structure in `Grid` is `matrix` which is a 9x9 matrix in identical format as the input matrix for the grid. This is the matrix
where the input matrix is copied to.

#### Auxiliary Data Structures

The main auxiliary data structures are the most interesting part of this class, besides the solver algorithm itself:

* `lines` - an array with 9 positions, each one, corresponding to a line in the grid, and functioning as a set where each bit represents a digit 
already present in that line.
* `cols` - an array with 9 positions, each one, corresponding to a column in the grid, and functioning as a set where each bit represents a digit 
already present in that column.
* `cells` - a 3x3 matrix, corresponding to a 3x3 cell that the grid is subdivided, with 9 positions, each one functioning as a set where each bit 
represents a digit already present in that cell.

#### Additional Auxiliary Data Structures

* `stk` - the stack to implement the backtracking algorithm. It uses an array of 81 positions. It uses the `push` and `pop` operators as shown in
the [algorithm](https://github.com/nilostolte/Sudoku#algorithm) below. The `push` operator not only stores the digit, its 
[binary representation](https://github.com/nilostolte/Sudoku#binary-representation-for-digits), 
the line and column (`i` and `j`) of the element inserted in a stack node (`StkNode`), _"pushing"_ the node in the stack, but also inserts the 
digit in the internal matrix (`matrix[i][j]`) as well as its binary representation into the auxiliary data structures, thus, updating the candidate
set of the new element inserted. The `pop` operation only removes the node from the stack, but the node is not garbage collected. It remains in the
stack as an unused element. Nodes are lazily allocated, as `null` elements are found while pushing.
* `cel` - an array with 9 positions, each one is the inverse mapping of the indices in the lines and columns transformed into indices in the 3x3
matrix `cells`.

#### Representing a set of present digits with bits

All main auxiliary data structures use a common notation to represent a set of digits present in the line, column, or cell, accordingly.
A bit is set to one at the position corresponding to a digit present in the set, or set to zero if it's position corresponds to a digit that 
is absent. By reversing the bits one gets the "candidate set" of digits that are still missing in the corresponding line, column or cell. For
a better understanding of this candidate set scheme, please refer to the 
[subsection](https://github.com/nilostolte/Sudoku#binary-representation-for-digits) explaining how digits are represented in binary.

Let's suppose a particular line, column or cell having the digits, 1, 3, 4 and 9. This set is then represented by the following binary number:

**100001101** = **0x10D**

* the first rightmost bit corresponds to the digit 1, and in this case it's present in the set already.
* the second bit on its left corresponds to the digit 2, and its clearly not present yet since its value is zero.
* bits three and four, corresponding to the digits 3 and 4, respectively, are clearly present, because they are both set to one.
* bits five, six, seven, and eight are all zeros, and thus, digits 5, 6, 7 and 8 are clearly absent in the set.
* bit 9 is 1. Therefore, the digit 9 is also present in the set.

#### Final Candidate Set

In order to obtain a candidate set for a given `matrix[i][j]` element of the grid one calculates:

**`lines[i] | cols[j] | cells[ cel[i] ][ cel[j] ]`**  (1)

The expression in (1) gives a set where all bits containing zeros correspond to the available digits that are possible to be in `matrix[i][j]`. 
The candidate set is detected by the absent elements in the set, that is, all bits which are zero. 

The interest in this notation is that the concatenation of all three sets is obtained by just using two bitwise or operations.

One can observe how `cel` inverse mapping works to access the corresponding cell in `cells`. First, `i` and `j` are used as indices in `cel`. `cel[i]` and `cel[j]` give the corresponding line and column in `cells`. Therefore, `cells[cel[i]][cel[j]]` corresponds to the cell where `matrix[i][j]` is contained.

## Algorithm

```java
    public void solve() {
        StkNode node;
        int digit = 1, code = 1, inserted;
        int i, j;
        char[] line = matrix[0];
        char c;
        i = j = 0;
        do {
            c = line[j];
            if (c == 0) {
                inserted = lines[i]|cols[j]|cells[cel[i]][cel[j]];
                for ( ; digit != 10 ; digit++, code <<= 1 ) {
                    if (( code & inserted ) == 0 ) {
                        push(i, j, code, digit);
                        digit = code = 1;
                        break;
                    }
                }
                if ( digit == 10 ) {            // no insertion -> backtrack to previous element
                    node = pop();               // pop previous inserted i, j, and digit
                    i = node.i;
                    j = node.j;
                    digit = node.digit;
                    code = node.code;
                    remove(node);               // remove digit from data structures
                    digit++; code <<= 1;        // let's try next digit;
                    line = matrix[i];           // maybe line has changed
                    continue;                   // short-circuit line by line logic
                }
            }
            if ( j == 8 ) {                     // line by line logic
                j = -1; i++;                    // last line element, advance to next line
                if (i < 9) line = matrix[i];    // update line from grid matrix
            }
            j++;                                // advance to next element in the line
        } while (i < 9);
    }
```

### Binary Representation for Digits

In the binary representation, a digit is always a power of two, since it's a number with only one bit set to 1 at the position corresponding 
to the digit. The table below shows the correspondance between digits and their binary representation:

| Digit | Binary Representation | Hexadecimal | Decimal |
| :---: | :-------------------: | :---------: | :-----: |
| 1     | **000000001**         | 0x001       | 1       |
| 2     | **000000010**         | 0x002       | 2       |
| 3     | **000000100**         | 0x004       | 4       |
| 4     | **000001000**         | 0x008       | 8       |
| 5     | **000010000**         | 0x010       | 16      |
| 6     | **000100000**         | 0x020       | 32      |
| 7     | **001000000**         | 0x040       | 64      |
| 8     | **010000000**         | 0x080       | 128     |
| 9     | **100000000**         | 0x100       | 256     |

The binary representation as exposed in the table above is often called here as the _"code"_ of the digit.

### Implementation of Digit Retrieval in Candidate Set

As we can see the variable `inserted` contains the "candidate set" for a given `matrix[i][j]`. This algorithm is quite simple but it
contains a major drawback. Since the digit is represented with a 1 bit in its corresponding position in variable `code`, and it accesses 
the candidate set in a sequential way, it loops until an empty bit is found (`( code & inserted ) == 0 )`) or if it finds no available 
candidate (`digit == 10`). 

This means that even if there are no available candidates, the algorithm has to loop over all the remaining bits sequentially. Even if the binary 
representation allows to deal with the candidate set with all elements in parallel, that is, all elements at once, we still have to access
it one by one sequentially even when there are no useful results. This problem is adressed with some partial solutions as shown [here](https://github.com/nilostolte/Sudoku#parallel-check-for-no-candidates) and 
[here](https://github.com/nilostolte/Sudoku#brachless-next-candidate-determination), but this later employs far too many operations, despite 
the fact it's a branchless solution. It's only interesting when associated with other optimizations as it has been done in the 
[C version](https://github.com/nilostolte/Sudoku#benchmarks-in-c).

### Stack and Backtracking implementation

Digits are tried in ascending order from 1 to 9 for each element in the grid that is not yet occupied. That's why `digit` and `code` 
variables are both initialized with 1. Every time a new digit is tried against the candidate set, and a successful candidate is found 
(that is, when `( code & inserted ) == 0 )`), the digit is pushed on the stack.

The `push` function also updates `matrix[i][j]`, `lines[i]`, `cols[j]` and `cells[cel[i]][cel[j]]` with the new digit. Please check the 
[code](https://github.com/nilostolte/Sudoku/blob/main/src/Grid.java) and the description of 
[`stk`](https://github.com/nilostolte/Sudoku#additional-auxiliary-data-structures) for details.

When no suitable candidate is found (that is, when `( code & inserted ) == 0 )` fails for every candidate tried), then the `for` loop
ends, and `digit == 10`. In this case, we need to backtrack, that is, remove the current candidate, and advance the previous inserted
digit to be the next candidate. This is taken care by the instructions found under the `if ( digit == 10 )` statement, where the previous
candidate is popped from the stack, removed from `matrix` and the auxiliary data structures (function `remove`), and advanced to
be the next candidate (`digit` is incremented and `code` is shifted left). Notice that this command sequence terminates with a `continue`
statement in order to skip the line by line logic. Since the line and column (`i` and `j`) of the element to be dealt next are already 
known (they were popped from the stack), modifying `i` or `j` is not required. Also of note, if all the possible candidates were 
tried, `digit` will become 10, the `for` loop is summarily skipped, and the flow goes back into this code sequence to backtrack once 
again, dealing with the cases of "cascaded" backtracking sequences.

This completes the backtracking mechanism, allowing, as can be easily infered, to obtain the solution of the input grid in the internal
matrix. As shown in [Main.java](https://github.com/nilostolte/Sudoku/blob/main/src/Main.java), the solution is printed using the function
`print`. 

## Parallel check for no candidates

The logic to check if there are no candidates with no loops is much more involved than what's done in the algorithm above, but its not rocket
science. It only requires more effort to use our bit representation in a smarter way.

### Mask to Filter Candidate Sets
Every power of two subtracted by one is always equal to a sequence of ones on the right of the position it was previously one (except in the
case of 0<sup>2</sup>, since there are no more binary digits on the right of 1). For example, the digit 8 in binary is 128 in our 
representation. When subtracted by one, that's 127, that is, 8 bits set to 1 on the right of bit 8:

**128 - 1 = 010000000 - 1 = 001111111**

By reversing every bit of this result one obtains a mask that's unique when all these bits are 1, that is, when there are no candidates from
the bit in the current position until the last bit:

**~001111111 = 110000000**

That is, by executing a bitwise _and_ operation (`&`) between this mask and a candidate set, and if the result is identical to this mask,
we can say there is no available candidates left in the candidate set, starting with the digit we are trying, 8 in this case.

Let's check the same logic with digit = 5:

**~(000010000 - 1) = ~000001111 = 111110000**

Then by testing if

**111110000 & inserted == 111110000**

What this is actually saying is that there are no candidates neither for 5, neither any digit above it. In other words, this is exactly the 
condition we were looking for.

One could call this as `reachable`, that is, more formally speaking what we've got is:

**`reacheable = (~(code-1)) & 0x1ff;`**

Notice that we have to filter out all bits above bit 9. Then the condition searched would be written like

**`if ( (inserted & reacheable ) == reacheable )`** (2)

### Changes in the Algorithm

In this case `if` statement (2) can substitute the following `if` statement in the algorithm:

**`if ( digit == 10 )`**

And we should place `if` statement (2) above the `for` loop statement instead of the order presented in the algorithm. In this 
case the `for` can be written with no final condition, since it would never be reached:

**`for ( ; ; digit++, code <<= 1 )`** (3)

The reason for that is that if there are no candidates, as calculated here, then the condition of the `if` statement (2) must be true
and, therefore, the `continue` statement relative to the do-while statement is executed before the `for` statement (3) is ever reached.
This obviously short-circuits the `for` statement (3), since it is now below the `if` statement (2). If the `for` statement (3) is reached,
the condition in the `if` statement (2) must have been false. In this situation there will always be a valid candidate and the
`break` command relative to the `for` statement (3) will be executed, always ending this loop with no need to test the end condition.

### Simplification of this Optimization - Eliminating the Mask

Another way to see this optimization is by observing that instead of calculating the mask as explained above, which implies using an intermediate
variable `reacheable`, one can infere an equivalent conclusion by simply discarding this variable and using the following test instead of if statement (2):

**`if ( (inserted + code ) > 511 )`**  (2a)

Which we call here an alternative to (2), or (2a) for short.

If there are only ones in `inserted` starting at the position of the 1 in `code`, adding `code` to `inserted` will result in
some value that is obviously beyond 511 (or 0x1ff). Therefore, we can detect the same situation with only the test (2a), not only
eliminating the need of calculating the mask, but also the need of the variable `reacheable`.

## Benchmarks

The benchmarks to measure algorithm performance were performed on an i7 2.2 Ghz machine in Java and in C. 
The [executable file compiled in C](https://github.com/nilostolte/Sudoku/blob/main/C/bin/sudoku.exe) has 
been done with optimization option `-O3` using the **gcc** compiler on Windows provided in 
[**w64devkit**](https://github.com/skeeto/w64devkit), which is a Mingw-w64 **gcc** compiler that is portable (can be installed by just
copying the directory structure in disk, SD card, or thumb drive).

### Main Test Grid

The benchmarks were executed with several different grids, but particularly with this
one, which is known to be time consuming in automatic methods, and used to compare speed of different methods
on the web:

 &nbsp; |  _1_  |  _2_  |  _3_  |  _4_  |  _5_  |  _6_  |  _7_  |  _8_  |  _9_ 
:------:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:|:-----:
**_1_** | <img src="8.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; |&nbsp; |&nbsp; |&nbsp; |&nbsp; |&nbsp; |
**_2_** |&nbsp; |&nbsp; | <img src="3.svg" width="32" height="32"> | <img src="6.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; |&nbsp; |&nbsp; |
**_3_** |&nbsp; | <img src="7.svg" width="32" height="32"> |&nbsp; |&nbsp; | <img src="9.svg" width="32" height="32"> |&nbsp; | <img src="2.svg" width="32" height="32"> |&nbsp; |&nbsp; |
**_4_** |&nbsp; | <img src="5.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; | <img src="7.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; |
**_6_** |&nbsp; |&nbsp; |&nbsp; |&nbsp; | <img src="4.svg" width="32" height="32"> | <img src="5.svg" width="32" height="32"> | <img src="7.svg" width="32" height="32"> |&nbsp; |&nbsp; |
**_6_** |&nbsp; |&nbsp; |&nbsp; | <img src="1.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; | <img src="3.svg" width="32" height="32"> |&nbsp; |
**_7_** |&nbsp; |&nbsp; | <img src="1.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; |&nbsp; | <img src="6.svg" width="32" height="32"> | <img src="8.svg" width="32" height="32"> |
**_8_** |&nbsp; |&nbsp; | <img src="8.svg" width="32" height="32"> | <img src="5.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; | <img src="1.svg" width="32" height="32"> |&nbsp; |
**_9_** |&nbsp; | <img src="9.svg" width="32" height="32"> |&nbsp; |&nbsp; |&nbsp; |&nbsp; | <img src="4.svg" width="32" height="32"> |&nbsp; |&nbsp; |

### Benchmarks in Java

The minimal time measured for the optimized algorithm to solve the above grid after several attempts was 10 miliseconds, 
and the double for the unoptimized algorithm. Nevertheless, the times verified were quite variable as usual in Java 
while measuring fast algorithms like this. This is the reason it would worth trying to implement it with an entirely 
compiled language (Java is only compiled when the JIT compiler is triggered) to verify if execution times are less 
variable. It looks like that for this kind of problem, an enterily compiled language would be more appropriate, since 
one expects similar times for the same grid running at different times. Unfortunately this is not the case for this 
Java implementation.

### Benchmarks in C

Astonishingly, execution times running the executable compiled in C were only slightly more constant than in Java. The 
times varied from 1.5 miliseconds to 5.26 miliseconds. However, these variations were considerably much less significant 
than in Java. Also, C offered roughly about an order of  magnitude to about twice less time than the Java implementation 
of the same optimized algorithm. Several optimizations were devised besides the ones mentioned below. After all these
optimizations were applied, one obtained a significant 
[improvement in performance](https://github.com/nilostolte/Sudoku#table-to-convert-from-bit-representation) and the
[Windows 64 executable supplied](https://github.com/nilostolte/Sudoku/blob/main/C/bin/sudoku.exe) was generated with
the resulting source code.

### Brachless Next Candidate Determination

The parallel test for no candidates allows to discard unnecessary `for` loop iterations, while also discarding the unecessary end 
condition of the `for` loop (since the order of the `if` statement (2) and the `for` statement was reversed). Nevertheless, for 
detecting the first candidate one still has to loop and test the digits one by one sequentially against the `inserted` set.

But there is a way to calculate the next candidate without any loop. The technique can be illustrated through and example.
Supposing the set `included = 101011110` (that is {9,7,5,4,3,2}, the set of digits already inserted) and 
`digit = 000000010` (2), one starts by adding both:

```
   101011110    // included digits set: {9,7,5,4,3,2}
 + 000000010    // digit = 2
```
Which is equal to **`000111100`**. One now does an exclusive or with `included`:
```
   101111100
 ^ 101011110
```
Which is equal to **`000111110`**. One now adds digit again:

```
   000111110
 + 000000010
```
Which is equal to **`001000000`**. The bit representation of the next candidate, is obtained by shifting one position to
right:

```
   001000000 >> 1
```
Which is equal to **`000100000`**. This corresponds to the digit 6, which is exactly the first zero bit found by
applying the for loop (3).

Therefore, assuming `code` as the bit representation of the digit, one calculates the next candidate doing:

```java
    code = (((code + inserted) ^ inserted) + code) >> 1; // branchless code calculation
```

The problem is that one only obtains the bit representation of the digit, not the digit itself. As, one can see, `digit` is
necessary to be able to use this technique.

### Branchless Transformation from Bit Representation

To obtain the digit from its code,  one "assembles" the bit configuration of the digit from its bit representation (`code`) as follows:

```java
    digit = ( code >> 8 ) |
            (( code & 0x40 ) >> 6 ) | 
            (( code & 0x140) >> 5 ) |
            (( code & 0xf0 ) >> 4 ) |
            (( code & 0x20 ) >> 3 ) |
            (( code & 0x14 ) >> 2 ) |
            (( code & 0x0c ) >> 1 ) |
            ( code & 3);
```

This conversion is not only complex to understand, but also requires a high number of operations. Trying out this code and the
brachless calculation of the next candidate as shown 
[previously](https://github.com/nilostolte/Sudoku/blob/main/README.md#brachless-next-candidate-determination), the minimal time
in C passed from 1.5 to 1.4 miliseconds, which apparently wouldn't seem to justify the effort. 

However, after multiple further opimizations, including using `register` variables, the minimal running time was reduced to 
1.2 microseconds. This corresponds to a speedup of roughly 20%, which starts to become quite consequential. It's clear that 
this is also consequence of the highly "imperative" way of implementing this [algorithm](https://github.com/nilostolte/Sudoku#algorithm)
which manifestly highly benefits the C implementation, that in itself is more easily optimizable by employing extremely low level
gimmicks that are absent in Java.

### Table to Convert from Bit Representation

Another way to do the calculation [above](https://github.com/nilostolte/Sudoku#branchless-transformation-from-bit-representation)
is using tables. For example, in C:

```C
    unsigned short c1[] = { 0, 1, 2, 0, 3 };
    unsigned short c2[] = { 0, 4, 5, 0, 6 };
    unsigned short c3[] = { 0, 7, 8, 0, 9 };
```
One can compose the digit from its bit representation `code` in the following way:

```C
    digit = c1[code & 7] | c2[(code >> 3) & 7] | c3[code >> 6];
```
This code is more understandable than the [previous](https://github.com/nilostolte/Sudoku#branchless-transformation-from-bit-representation)
one. If the digit is 1, 2 or 3, one simply filters the first 3 bits of `code`and index the table `c1` with this result. Position 3 is invalid 
since `code` has only 1 bit set, and, thus, it can't be 3. Notwithstanding, the resulting operation can be zero, in the case the binary
representation doesn't have any bit set in that range. In this case, to satisfy the branchless logic, the table value is 0.
If the digit is 4, 5 or 6, one shifts `code` to the right 3 positions and filters the first 3 bits and index the table `c2`
with this result. The same logic applies to digits 7, 8 and 9, using table `c3`. Since one doesn't know which one is correct, one simply
apply a binary or operation with the 3 results, after all only one of them contains the good digit. The other two will be zero.

Trying this solution instead of the [previous](https://github.com/nilostolte/Sudoku#branchless-transformation-from-bit-representation),
had a significant impact in the minimal execution time of the compiled C code, that was reduced to practically 1 millisecond, that is,
an optimization of more than 30%, since the initial minimal time in our comparisons was 1.5 milliseconds.

## Conclusion

The several optimizations proposed are complex to understand and most of them do not result in a significant speed up. The 
[initial algorithm](https://github.com/nilostolte/Sudoku#algorithm) and 
in the [Java](https://github.com/nilostolte/Sudoku/tree/main/src) and [C](https://github.com/nilostolte/Sudoku/tree/main/C/src) 
codes, are more clear and relatively easy to understand after the binary representation is understood.

The idea of parallelizing the code by dealing with the whole candidate set at once just using binary representation is promising.
However, it falls short if one was thinking in using its intrisic parallelism in the entire algorithm. As seen 
[above](https://github.com/nilostolte/Sudoku#brachless-next-candidate-determination), the
approach allows branchless solutions for the sequential search of a candidate from an arbitrary digit value, which only partially
exploits this intrisic paralellism. Notwithstanding, it's heavily relying on the integer addition carry propagation mechanism, 
which is actually a sequential mechanism, but implemented highly efficiently in hardware. This is just additional ingenuity, but
not the same approach. The actual problem in this partial solution is that it's highly complex and requires a high number 
of operations. Thus, it highly diverges from the extreme simplicity of the original algorithm. Fortunately, associated with numerous 
other low level optimizations in C language, it contributed to a significant 
speedup (as can be seen [here](https://github.com/nilostolte/Sudoku#branchless-transformation-from-bit-representation)), and
a better speedup as well as less complexity (as seen [here](https://github.com/nilostolte/Sudoku#table-to-convert-from-bit-representation)). 

A comparative test between the Java implementation and an identical C inplementation has given a considerable advantage to the C
implementation, not only in terms of raw performance, but also in terms of less variability in times measured for solving
the same grid, even though, variable execution times were also present in the C implementation. This was expected since Java
activates the JIT compiler not quite regularly in codes that are executed in short ammounts of time like this one.

Given the extremely short execution times, the low level nature of the [original algorithm](https://github.com/nilostolte/Sudoku#algorithm),
and the considerable amount of low level optmizations that are possible in C language, one may confortably conclude that C is the
most appropriate language to use the algorithm, since it will provide faster answers. This means, that the C implementation can be seen
as the ideal engine for an interactive program where the grid can be entered through a GUI and that the solution must be supplied
in real time when it is requested by the user.

