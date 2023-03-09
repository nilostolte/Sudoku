# Sudoku
Simple 9x9 Sudoku brute force solver with intrinsic parallel candidate set processing thanks to the use of bit representation for the 1-9 digits as well as bitwise operations allowing to test all the candidates at once.

It can be upgraded for 16x16 or 25x25 grids.

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
the [algorithm](https://github.com/nilostolte/Sudoku#algorithm) below. The `push` operator not only stores the digit, its binary presentation, 
the line and column (`i` and `j`) of the element inserted in a stack node (`StkNode`), _"pushing"_ the node in the stack, but also inserts the 
digit in the internal matrix (`matrix[i][j]`) as well as its binary representation into the auxiliary data structures, thus, updating the candidate
set of the new element inserted. The `pop` operation only removes the node from the stack, but the node is not garbage collected. It remains in the
stack as an unused element. Nodes are lazily allocated, as `null` elements are found while pushing.
* `cel` - an array with 9 positions, each one is the inverse mapping of the indices in the lines and columns transformed into indices in the 3x3
matrix `cells`.

#### Representing a set of present digits with bits

All main auxiliary data structures use a common notation to represent a set of digits present in the line, column, or cell, accordingly.
A bit is set to one at the position corresponding to a digit present in the set, or set to zero if it's position corresponds to a digit that 
is absent. By reversing the bits one gets the "candidate set" of digits that are still missing in the corresponding line, column or cell.

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

As we can see the variable `inserted` contains the "candidate set" for a given `matrix[i][j]`. This algorithm is quite simple but it
contains a major drawback. Since the digit is represented with a 1 bit in its corresponding position in variable `code`, and it accesses 
the candidate set in a sequential way, it loops until an empty bit is found (`( code & inserted ) == 0 )`) or if it finds no available 
candidate (`digit == 10`). 

This means that even if there are no available candidates, the algorithm has to loop over all nine bits sequentially. Even if the binary 
representation allows to deal with the candidate set with all elements in parallel, that is, all elements at once, we still have to access
it one by one sequentially even when there are not useful results.

The `push` function also updates `matrix[i][j]`, `lines[i]`, `cols[j]` and `cells[cel[i]][cel[j]]` with the new digit. Please check the 
[code](https://github.com/nilostolte/Sudoku/blob/main/src/Grid.java) and the description of 
[`stk`](https://github.com/nilostolte/Sudoku#additional-auxiliary-data-structures) for details.

### Parallel check for no candidates

The logic to check if there are no candidates with no loops is much more involved than what's done in the algorithm above, but its not rocket
science. It only requires more effort to use our bit representation in a smarter way.

#### Binary Representation for Digits
In the binary representation, a digit is always a power of two, since it's a number with only one bit set to 1 at the position corresponding 
to the digit.The table below shows the correspondance between digits and their binary representation:

| Digit | Binary Representation | Hexadecimal | Decimal |
| :---: | :-------------------: | :---------: | :-----: |
| 1     | 000000001             | 0x001       | 1       |
| 2     | 000000010             | 0x002       | 2       |
| 3     | 000000100             | 0x004       | 4       |
| 4     | 000001000             | 0x008       | 8       |
| 5     | 000010000             | 0x010       | 16      |
| 6     | 000100000             | 0x020       | 32      |
| 7     | 001000000             | 0x040       | 64      |
| 8     | 010000000             | 0x080       | 128     |
| 9     | 100000000             | 0x100       | 256     |

#### Mask to Filter Candidate Sets
Every power of two subtracted by one is always equal to a sequence of ones on the right of the position it was previously one. For example, the 
digit 8 in binary is 128 in our representation. When subtracted by one, that's 127, that is, 8 bits set to 1 on the right of bit 8:

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

#### Changes in the Algorithm

In this case this `if` statement can substitute this one in the algorithm:

**`if ( digit == 10 )`**

And we should place `if` statement (2) above the `for` loop statement instead of the order presented in the algorithm. In this 
case the `for` can be written with no final condition, since it would never be reached:

**`for ( ; ; digit++, code <<= 1 )`** (3)

The reason for that is that if there are no candidates, as calculated here, then the condition of the `if` statement (2) must be true
and, therefore, the `continue` statement relative to the do-while statement is executed before the `for` statement (3) is ever reached.
This obviously short-circuits the `for` statement (3), since it is now below the `if` statement (2). If the `for` statement (3) is reached,
the condition in the `if` statement (2) must have been false. In this situation there will always be a valid candidate and the
`break` command relative to the `for` statement (3) will be executed, always ending this loop with no need to test the end condition.

## Conclusion

The parallel test for no candidates allows to discard unnecessary `for` loop iterations, while also discarding the unecessary end 
condition of the `for` loop (since the order of the `if` statement (2) and the `for` statement was reversed). Nevertheless, for 
detecting the first candidate one still has to loop and test the digits one by one sequentially against the `inserted` set.

The resulting optimized algorithm is a good start but it's a bit complex to understand. The initial algorithm, as shown here and 
in the code, is more clear and relatively easy to understand after the binary representation is understood.

The idea of parallelizing the code by dealing with the whole candidate set at once just using binary representation is promising.
However, it falls short if one thinks in using its intrisic parallelism in the entire algorithm. 

