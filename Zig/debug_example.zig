const std = @import("std");

var grid = [_]u8{0} ** 81;        // Sudoku grid stored linearly here

const matrix = fill9x9: {         // matrix array allows accessing a  
   var m : [9][*]u8 = undefined;  // grid element as a matrix, giving  
   var pt : [*]u8 = &grid;        // i and j: element = matrix[i][j]
   for (0..9) |i| {               //
      m[i] = pt;                  // stores the pointers of each line
	  pt += 9;                    // at each position of matrix array
   }                              //
   break :fill9x9 m;              // initializes matrix array with m
};                                //

var   lines   = [_]u9{0} ** 9;    // all elements present in each line
var   columns = [_]u9{0} ** 9;    // all elements present in each column
var   cells   = [_]u9{0} ** 9;    // all elements present in each cell
// i' = cindx[i], 
// j' = cindx[j]
// cell[i'][j'] = elements in the cell of element in matrix[i][j]
const cindx   = [_]usize{ 0,0,0, 1,1,1, 2,2,2 };

const cell = fill3x3: {           // cell array allows accessing all elements
   var m : [3][*]u9 = undefined;  // present in a cell using cells as a matrix,
   var pt : [*]u9 = &cells;       // in this way: cell[cindx[i]][cindx[j]]
   for (0..3) |i| {               // 
      m[i] = pt;                  // stores the pointers of each line
	  pt += 3;                    // at each position of cell array
   }                              //
   break :fill3x3 m;              // initializes cell array with m
};                                //

const c1 = [_]u8{ 0, 1, 2, 0, 3 };
const c2 = [_]u8{ 0, 4, 5, 0, 6 };
const c3 = [_]u8{ 0, 7, 8, 0, 9 };

fn reinit() void {                // reinitilizes lines, columns and cells
   for (0..9) |i| {
      lines[i]   = 0;
      columns[i] = 0;
      cells[i]   = 0;
   }
}

//
// sets a new grid giving all elements line by line in a string
//

pub fn set( s : [:0]const u8 ) void {
   var k : usize = 0;
   var code : u9 = undefined;
   var c : u4 = undefined;
   var line : [*]u8 = undefined;
   reinit(); // resets data structures to allow several sets
   for ( 0..9 ) |i| {
      line = matrix[i];
      for ( 0..9 ) |j| {
      	c = @intCast(s[k]-'0');
      	if (s[k] == '.') c = 0;
      	if (c != 0) {
           code = @as(u9,1) << (c-1);
           // check if there is no error before inserting
           if (((lines[i]|columns[j]|cell[cindx[i]][cindx[j]]) & code) != 0 ) {
           	  std.debug.print("*** Duplicate digit {} at position {}, line {}, column {}\n", .{c, k, i, j});
           	  unreachable;
           }
           lines[i] |= code;
           columns[j] |= code;
           cell[cindx[i]][cindx[j]] |= code;
        }			
      	line[j] = c;
      	if (c != 0) {
      	   print();
      	   std.debug.print(
              "Current digit {}\nposition in string {}\n" ++
              "line {}\ncolumn {}\ncode {b}\n", 
              .{c, k, i, j, code}
           );
      	   @breakpoint();
      	}
      	k+= 1;
      }
   }
}

//
// prints the grid on the console
//

pub fn print() void {
	var line : [*]u8 = undefined;
	var c : u8 = undefined;
	for ( 0..9 ) |i| {
		line = matrix[i];
		std.debug.print("|",.{});
		for ( 0..9 ) |j| {
			c = line[j];
			c = if (c == 0) ' ' else (c + 48);
			std.debug.print("{c}|", .{c});
		}
		std.debug.print("\n",.{});
	}
}

test " => testing set and print functions" {
    set("800000000003600000070090200050007000000045700000100030001000068008500010090000400");
	std.debug.print("\n===================\n    Input Grid\n===================\n", .{});
	print();
}

pub fn main() !void {
    set(
      "800000000003600000070090200" ++
      "050007000000045700000100030" ++
      "001000068008500010090000400"
    );
}

