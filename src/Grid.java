import java.util.Stack;

public class Grid {
    private char[][] matrix;    /* matrix holding the grid */

    /* AUXILIARY DATA STRUCTURES */
    private char[] lines;       /* tracks occupancy of all lines */
    private char[] cols;        /* tracks occupancy of all columns */

    /* maps line or column indexes to cell indexes in a 3x3 matrix*/
    static final private char[] cel = { 0,0,0, 1,1,1, 2,2,2 };
    private char[][] cells;     /* 3x3 matrix tracking occupancy of 9 cells */

    /* STATIC METHODS */

    /* fills 3x3 matrix with its line by line string representation */
    static void set(char[][] g, String s) {
        int i, j, k;
        char[] line;
        char c;
        for (k = 0, i = 0; i < 9; i++) {
            line = g[i];
            for (j = 0; j < 9; k++, j++) {
                line[j] = (char) (s.charAt(k)-'0');
            }
        }
    }
    /* default constructor: grid must be initialized to before calling solve */
    public Grid() {
        matrix = new char[9][9];
        cells = new char[3][3];
        lines = new char[9];
        cols = new char[9];
    }

    /* reinitializes grid with a new matrix */
    public void reinit(char[][] g) {
        int i, j;
        /* reset data structures before initializing */
        for (i = 0; i < 9; i++) { /* resets lines and columns occupancy */
            lines[i] = 0;
            cols[i] = 0;
        }
        for (i = 0; i < 3; i++) { /* resets cells occupancy */
            for (j = 0; j < 3; j++) {
                cells[i][j] = 0;
            }
        }
        /* initializes grid as usual */
        init(g);
    }

    /* initializes grid with supplied matrix or ends if grid is invalid */
    public void init(char[][] g) {
        int i, j, code;
        char[] gl, line;
        char c;
        for (i = 0; i < 9; i++) {
            gl = g[i];
            line = matrix[i];
            for (j = 0; j < 9; j++) {
                c = gl[j];
                line[j] = c;
                if (c != 0) {
                    code = 1<<(c-1);
                    /* check if there is no error before inserting */
                    if (((lines[i]|cols[j]|cells[cel[i]][cel[j]]) & code) != 0 ) {
                        System.out.print("*** Duplicate digit " + c + " at gl " + i + ", column " + j +"\n");
                        System.exit(0);
                    }
                    lines[i] |= code;
                    cols[j] |= code;
                    cells[cel[i]][cel[j]] |= code;
                }
            }
        }
        stkptr = -1; // resets stack pointer
    }

    /******** SOLUTION LOGIC ********/

    /* brut force line by line grid solver with backtracking logic */
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

    /* simple and fast implementation of a stack for backtracking */
    private class StkNode {
        int i;
        int j;
        int code;
        int digit;
    }
    private StkNode[] stk = new StkNode[81];
    private int stkptr = -1;
    private void push(int i, int j, int code, int digit){
        stkptr++;   /* combines stack push with lazy memory allocation for node */
        if (stk[stkptr] == null) stk[stkptr] = new StkNode();
        StkNode node = stk[stkptr];
        node.i = i;
        node.j = j;
        node.code = code;
        node.digit = digit;
        // insert
        matrix[i][j] = (char) digit;
        lines[i] |= code;
        cols[j] |= code;
        cells[cel[i]][cel[j]] |= code;
    }

    private StkNode pop() {
        return stk[stkptr--];
    }

    /* removes digit in stack node from matrix and data structures */
    private void remove(StkNode node) {
        int i = node.i;
        int j = node.j;
        matrix[i][j] = 0;
        char code = (char) ~node.code;
        lines[i] &= code;
        cols[j] &= code;
        cells[cel[i]][cel[j]] &= code;
    }

    /* displays grid */
    public void print() {
        int i, j;
        char[] line;
        char c;
        for (i = 0; i < 9; i++) {
            line = matrix[i];
            System.out.print("|");
            for (j = 0; j < 9; j++) {
                c = line[j];
                c = (c == 0)?' ': (char) (c + 48);
                System.out.print(c);
                System.out.print("|");
            }
            System.out.print("\n");
        }
    }
}
