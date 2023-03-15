#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "grid.h"

unsigned char **matrix;    /* matrix holding the grid */

/* AUXILIARY DATA STRUCTURES */
unsigned short *lines;       /* tracks occupancy of all lines */
unsigned short *cols;        /* tracks occupancy of all columns */

/* maps line or column indexes to cell indexes in a 3x3 matrix*/
unsigned short *cel;
unsigned short **cells;     /* 3x3 matrix tracking occupancy of 9 cells */

void init_structures() {
	matrix = malloc(9 * sizeof(unsigned char *));
	unsigned char *m1 = malloc(81 * sizeof(unsigned char));
	int i, j;
	for (i = 0, j = 0; i < 9; j += 9, i++) {
		matrix[i] = m1 + j;
	}
	lines = malloc(9 * sizeof(unsigned short));
	cols = malloc(9 * sizeof(unsigned short));
	cel = malloc(9 * sizeof(unsigned short));
	cells = malloc(3 * sizeof(unsigned short *));
	unsigned short *m2 = malloc(9 * sizeof(unsigned short));
	for (i = 0, j = 0; i < 3; j += 3, i++) {
		cells[i] = m2 + j;
		cel[j] = cel[j+1] = cel[j+2] = i;
	}
	reinit();
}

void reinit() {
	int i, j;
	/* reset data structures */
	for (i = 0; i < 9; i++) { /* resets lines and columns occupancy */
		lines[i] = 0;
		cols[i] = 0;
	}
	for (i = 0; i < 3; i++) { /* resets cells occupancy */
		for (j = 0; j < 3; j++) {
			cells[i][j] = 0;
		}
	}
}

void set(char *s) {
	int i, j, k, code;
	unsigned char *line, c;
	for (k = 0, i = 0; i < 9; i++) {
		line = matrix[i];
		for (j = 0; j < 9; k++, j++) {
			c = (s[k]-'0');
			if (s[k] == '.') c = 0;
			if (c != 0) {
				code = 1 << (c-1);
				/* check if there is no error before inserting */
				if (((lines[i]|cols[j]|cells[cel[i]][cel[j]]) & code) != 0 ) {
					printf("*** Duplicate digit %c at line %d, column %d\n", c, i, j);
					exit(1);
				}
				lines[i] |= code;
				cols[j] |= code;
				cells[cel[i]][cel[j]] |= code;
            }			
			line[j] = c;
		}
	}
}

/* simple and fast implementation of a stack for backtracking */
struct StkNode {
	unsigned short i;
	unsigned short j;
	unsigned short code;
	unsigned short digit;
};

struct StkNode *stk;
int stkptr;

void init_stack() {
	stk = malloc(sizeof(struct StkNode));
	stkptr = -1;
}

struct StkNode *pop() {
	struct StkNode *node = stk + stkptr;
	if ( stkptr < 0 ) {
		print();
		exit(1);
	}
	stkptr--;
	int i = node->i;
	int j = node->j;
	matrix[i][j] = 0;
	unsigned short code =  ~node->code;
	lines[i] &= code;
	cols[j] &= code;
	cells[cel[i]][cel[j]] &= code;
	return node;
}

void push(int i, int j, int code, int digit){
	stkptr++;
	struct StkNode *node = stk + stkptr;
	node->i = i;
	node->j = j;
	node->code = code;
	node->digit = digit;
	// insert
	matrix[i][j] = (char) digit;
	lines[i] |= code;
	cols[j] |= code;
	cells[cel[i]][cel[j]] |= code;
}

/* brute force line by line grid solver with improved performance */
void solve() {
	struct StkNode *node;
	int digit = 1, code = 1, inserted, reacheable;
	int i = 0, j = 0;
	unsigned char *line = matrix[0];
	unsigned c;
	do {
		c = line[j];
		//print();
		if (c == 0) {
			inserted = lines[i]|cols[j]|cells[cel[i]][cel[j]];
			for ( ; digit < 10; digit++, code <<= 1 ) {
				if ( (code & inserted) == 0 ) {
					push(i, j, code, digit);
					digit = code = 1;
					break;
				}
			}
			if ( digit == 10 ) {
				node = pop();               // pop previous inserted i, j, and digit
				i = node->i;
				j = node->j;
				digit = node->digit;
				code = node->code;
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
	stkptr = -1; // resets stack pointer
}

void print() {
	int i, j;
	unsigned char *line;
	unsigned char c;
	for (i = 0; i < 9; i++) {
		line = matrix[i];
		printf("|");
		for (j = 0; j < 9; j++) {
			c = line[j];
			c = (c == 0)?' ': (char) (c + 48);
			printf("%c|", c);
		}
		printf("\n");
	}
}
	