# Sudoku
Simple 9x9 Sudoku brute force solver with intrinsic parallel candidate list processing thanks to the use of bit representation for the 1-9 digits as well as bitwise operations allowing to test all the candidates at once.

## Grid

This is the [class](https://github.com/nilostolte/Sudoku/blob/main/src/Grid.java) containing the grid to be solved. 

### Input 

The grid can be initialized using a 9x9 matrix of type `char[][]` or through a linear string containing all the elements, representating 
empty elements as 0, both given line by line. The `char[][]` is the unique input, however, and it must exist before being able to use
any other input format. Even though the 9x9 matrix contains characters (it's a `char[][]`), the digits are not represented as ASCII or Unicode
characters but rather as integers. In other words, the character '0' is actually represented by 0, and so forth.

In the string input format the string is just copied over the existing input `char[][]` matrix using the static function `set`. This string uses ASCII representation
for the digits which are converted to integers by the function `set`.

An additional representation is possible, as illustrated in [main.java](https://github.com/nilostolte/Sudoku/blob/main/src/Main.java), by 
representing the charcater '0' by the character '.' in the string. In this case one adds `.replace('.','0')` at the end of the string as shown.

Both string input formats are common representations of Sudoku grids on the web.

### Data Structures

The main data structure in the is the `matrix` which is a 9x9 matrix in identical format as the input matrix for the grid. This is the matrix
where the input matrix is copied to.

#### Auxiliary Data Structures

The main auxiliary data structures are the most interesting part of this class, besides the solver algorithm itself:

* `lines` - an array with 9 positions, each one, corresponding to a line in the grid, and functioning as a list where each bit represents a digit 
already present in that line.
* `cols` - an array with 9 positions, each one, corresponding to a column in the grid, and functioning as a list where each bit represents a digit 
already present in that column.
* `cells` - a 3x3 matrix, corresponding to a 3x3 cell that the grid is subdivided, with 9 positions, each one functioning as a list where each bit 
represents a digit already present in that cell.

#### Additional Auxiliary Data Structures

* `stk` - the stack to implement the backtracking algorithm. It uses an array of 81 positions. No further description of this structure is given
in this documentation since the way it works is quite straightforward and easy to understand in the code.
* `cel` - an array with 9 positions, each one is the inverse mapping of the indices in the lines and columns transformed into indices in the 3x3
matrix `cells`.

#### Representing a list of present digits with bits

All main auxiliary data structures use a common notation to represent a list of digits present in the line, column, or cell, accordingly.
A bit is set to one at the position corresponding to a digit present in the list, or set to zero if it's position corresponds to a digit that 
is absent. By reversing the bits one gets the "candidate list" of digits that are still missing in the corresponding line, column or cell.

Let's suppose a particular line, column or cell having the digits, 1, 3, 4 and 9. This list is then represented by the following binary number:

**100001101** = **0x10D**

* the first rightmost bit corresponds to the digit 1, and in this case it's present in the list already.
* the second bit on its left corresponds to the digit 2, and its clearly not present yet since its value is zero.
* bits three and four, corresponding to the digits 3 and 4, respectively, are clearly present, because they are both set to one.
* bits five, six, seven, and eight are all zeros, and thus, digits 5, 6, 7 and 8 are clearly absent in the list.
* bit 9 is 1. Therefore, the digit 9 is also present in the list.

#### Final Candidate List

In order to obtain a candidate list for a given `matrix[i][j]` element of the grid one calculates:

**`lines[i] | cols[j] | cells[ cel[i] ][ cel[j] ]`**  (1)

The expression in (1) gives a list where all bits containing zeros correspond to the available digits that are possible to be in `matrix[i][j]`. 
The candidate list is detected by the absent elements in the list, that is, all bits which are zero. 

The interest in this notation is that the concatenation of all three lists is obtained but just using two bitwise or operations.

One can observe how `cel` inverse mapping works to access the corresponding cell in `cells`. First, `i` and `j` are used as indices in `cel`. `cel[i]` and `cel[j]` give the corresponding line and column in `cells`. Therefore, `cells[cel[i]][cel[j]]` corresponds to the cell where `matrix[i][j]` is contained.

### Algorithm

```java
    public void solve() {
        StkNode node;
        int digit = 1, code = 1, reacheable;
        int i, j;
        char[] line = matrix[0];
        char c;
        i = j = 0;
        do {
            c = line[j];
            if (c == 0) {
                reacheable = lines[i]|cols[j]|cells[cel[i]][cel[j]];
                for ( ; digit != 10 ; digit++, code <<= 1 ) {
                    if (( code & reacheable ) == 0 ) {
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

As we can see the variable `reacheable` contains the "candidate list" for a given `matrix[i][j]`. This algorithm is quite simple but it
contains a major drawback. Since the digit is represented with a 1 bit in its corresponding position in variable `code`, and it accesses 
the candidate list in a sequential way, it loops until an empty bit is found (`( code & reacheable ) == 0 )`) or if it finds no available 
candidate (`digit == 10`). 

This means that even if there are no available candidates the algorithm has to loop over all nine bits sequentially. Even if the binary 
representation allows to deal with the candidate list with all elements in parallel, that is, all elements at once, we still have to access
it one by one sequentially even when there are not useful results.


 



