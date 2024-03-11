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


// simple and fast implementation of a stack for backtracking
const StkNode = packed struct {
	code: u16,
	i: u8,
	j: u8
};

const Stack  = struct {
    stk: [81]StkNode,
    pt: isize,

    pub fn init() Stack {
       return Stack {
          .stk = undefined,
          .pt = -1,
       };
    }

    pub fn size(self: *Stack) isize { // for testing purposes
       return self.pt + 1;
    }

    pub fn reset(self: *Stack) void {
       self.pt = -1;
    }

    pub fn push(self: *Stack, i: u8, j: u8, code: u16) callconv(.Inline) void {
       self.pt += 1;
       self.stk[@intCast(self.pt)] = .{
         .i = i,
         .j = j,
         .code = code,
       };
       //@prefetch(&matrix[i][j], .{.rw = .write, .locality = 0, .cache = .data});
       matrix[i][j] = c1[code&7]|c2[(code>>3)&7]|c3[code>>6];
       const code9 : u9 = @intCast(code);
       //@prefetch(&lines[i], .{.rw = .write, .locality = 0, .cache = .data});
       lines[i] |= code9;
       //@prefetch(&columns[j], .{.rw = .write, .locality = 0, .cache = .data});
       columns[j] |= code9;
       cell[cindx[i]][cindx[j]] |= code9;
       //cell[(i+@popCount(i))>>2][(j+@popCount(j))>>2]  |= code9;
    }

    pub fn pop(self: *Stack) callconv(.Inline) *StkNode {
       const node = &self.stk[@intCast(self.pt)];
       const i = node.i;
       const j = node.j;
       const code9 : u9 = ~@as(u9,@truncate(node.code));
       //@prefetch(&matrix[i][j], .{.rw = .write, .locality = 0, .cache = .data});
       matrix[i][j] = 0;
       //@prefetch(&lines[i], .{.rw = .write, .locality = 0, .cache = .data});
       lines[i] &= code9;
       //@prefetch(&columns[j], .{.rw = .write, .locality = 0, .cache = .data});
       columns[j] &= code9;
       cell[cindx[i]][cindx[j]] &= code9;
       //cell[(i+@popCount(i))>>2][(j+@popCount(j))>>2]  &= code9;
       self.pt -= 1;
       return node;
    }
};

var stack = Stack.init();

test " => testing push and pop functions" {
	std.debug.print("\nelement ({},{}) = {}\n", .{2, 0, matrix[2][0]});
    std.debug.print("elements in line   {b}\n", .{lines[2]});
    std.debug.print("elements in column  {b}\n", .{columns[0]});
    std.debug.print("elements in cell    {b}\n", .{cell[0][0]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
	stack.push(2,0,0b1000);
	std.debug.print("\n=> ***push executed***\n\n", .{});
	std.debug.print("===================\n   Changed Grid\n===================\n", .{});
	print();
	std.debug.print("\nelement ({},{}) = {}\n", .{2, 0, matrix[2][0]});
    std.debug.print("code pushed             {b}\n", .{0b1000});
    std.debug.print("elements in line   {b}\n", .{lines[2]});
    std.debug.print("elements in column  {b}\n", .{columns[0]});
    std.debug.print("elements in cell    {b}\n", .{cell[0][0]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
	const node = stack.pop();
	std.debug.print("\n=> ***pop executed***\n\n", .{});
	std.debug.print("element ({},{}) = {}\n", .{node.i, node.j, matrix[2][0]});
    std.debug.print("code poped              {b}\n", .{node.code});
    std.debug.print("elements in line   {b}\n", .{lines[node.i]});
    std.debug.print("elements in column  {b}\n", .{columns[node.j]});
    std.debug.print("elements in cell    {b}\n", .{cell[0][0]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
}

pub fn solve() void {
	var node : *StkNode = undefined;
	var code : u16 = 1;
	var inserted : u16 = undefined;
	var j : u8 = 0;
	var i : u8 = 0;
	var line : [*]u8 = matrix[0];
	var li : u16 = lines[0];
	var ci : [*]u9 = cell[0];
	var c : u8 = undefined;
	@prefetch(&line[0], .{.rw = .read, .locality = 0, .cache = .data});
	while (true) {
	   c = line[j];
	   if ( c == 0 ) {                     // jump over non empty elements
	     // "inserted" is the occupation set, the inverse of the candidate set
	     inserted = li|columns[j]|(ci[cindx[j]]);
	     // if adding candidate with occupation set overflows -> no candidate
	     if ( (inserted + code ) >= 512 ) {// backtrack if there isn't any candidate
	       node = stack.pop();             // pop previous inserted i, j, and code
	       i = node.i;
	       j = node.j;
	       line = matrix[i];               // line might have changed
	       ci = cell[cindx[i]];
	       //ci = cell[(i+@popCount(i))>>2];
	       li = lines[i];
	       code = (node.code) << 1;        // get next candidate
	       @prefetch(&line[j], .{.rw = .read, .locality = 0, .cache = .data});
	       continue;                       // short-circuits line by line logic
	     }
	     // chosen candidate is the next empty place in the occupation set
	     code = (((inserted + code ) ^ inserted) + code) >> 1; 
	     stack.push(i, j, code);           // store and save candidate
	     li |= code;
	     code = 1;                         // next candidate starts with 1
	   }
	   if ( j == 8 ) {                     // reached last element in the line
	     if ( i == 8 ) break;              // reached last element -> exit
	     i += 1;                           // go to the next line
	     j = 0;                            // starts with first element in the line
	     line = matrix[i];                 // update line from grid matrix
	     ci = cell[cindx[i]];              // update cell helper
	     li = lines[i];                    // update lines helper
	     continue;
	   }
	   j += 1;                             // next element in the line
	   @prefetch(&line[j], .{.rw = .read, .locality = 0, .cache = .data});
	}
	stack.reset();
}


//pub fn main() !void {
//    set("800000000003600000070090200050007000000045700000100030001000068008500010090000400");
//	std.debug.print("\n===================\n    Input Grid\n===================\n", .{});
//	print();
//	var timer = try std.time.Timer.start();
//	solve();
//    const time_0 : u64 = timer.read();
//	std.debug.print("\n===================\n     Solution\n===================\n", .{});
//    print();
//	@setFloatMode(.Optimized);
//    const ftime =  @as(f64,@floatFromInt(time_0))/1000000.0;
//    std.debug.print("\ntime in milliseconds: {d:.5}", .{ftime} );
//}
