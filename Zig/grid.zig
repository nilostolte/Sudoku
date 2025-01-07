
const std = @import("std");

var grid = [_]u8{0} ** 81;        // Sudoku grid stored linearly here

var   lines   = [_]u16{0} ** 9;   // all elements present in each line
var   columns = [_]u16{0} ** 9;   // all elements present in each column
var   cells   = [_]u16{0} ** 9;   // all elements present in each cell

const cell = fill3x3: {           // cell array allows accessing all elements
   var m : [3][*]u16 = undefined; // present in a cell using cells as a matrix,
   var pt : [*]u16 = &cells;      // in this way: cell[i div 3][j div 3]
   for (0..3) |i| {               // 
      m[i] = pt;                  // stores the pointers of each line
      pt += 3;                    // at each position of cell array
   }                              //
   break :fill3x3 m;              // initializes cell array with m
};                                //

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
   var code : u16 = undefined;
   var c : u4 = undefined;
   var index : usize = 0;
   var ci : [*]u16 = undefined;
   reinit(); // resets data structures to allow solving several games
   for ( 0..9 ) |i| {
      ci = cell[@divTrunc(i, 3)];
      for ( 0..9 ) |j| {
         c = @intCast(s[index]-'0');
         if (s[index] == '.') c = 0;
         if (c != 0) {
            code = @as(u16,1) << (c-1);
            // check if there is no error before inserting
            if (((lines[i]|columns[j]|ci[@divTrunc(j, 3)]) & code) != 0 ) {
                std.debug.print("*** Duplicate digit {} at position {}, line {}, column {}\n", .{c, index, i, j});
                unreachable;
            }
            lines[i] |= code;
            columns[j] |= code;
            ci[@divTrunc(j, 3)] |= code;
         }      
         grid[index] = c;
         index += 1;
      }
   }
}

//
// prints the grid on the console
//

pub fn print() void {
  var c : u8 = undefined;
  var index : usize = 0;
  for ( 0..9 ) |_| {
     std.debug.print("|",.{});
     for ( 0..9 ) |_| {
        c = grid[index];
        c = if (c == 0) ' ' else (c + 48);
        std.debug.print("{c}|", .{c});
        index += 1;
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

    pub fn push(self: *Stack, i: u16, j: u16, code: u16) callconv(.Inline) void {
       self.pt += 1;
       self.stk[@intCast(self.pt)] = .{
         .code = code,
         .i = @truncate(i),
         .j = @truncate(j),
       };
    }

    pub fn pop(self: *Stack) callconv(.Inline) *StkNode {
       const node = &self.stk[@intCast(self.pt)];
       self.pt -= 1;
       return node;
    }
};

var stack = Stack.init();

test " => testing push and pop functions" {
    const i : usize = 2;
    const j : usize = 0;
    var index : u8 = (i<<3) + i + j;
    std.debug.print("\nelement ({},{}) = {}\n", .{i, j, grid[index]});
    std.debug.print("elements in line   {b}\n", .{lines[i]});
    std.debug.print("elements in column  {b}\n", .{columns[j]});
    std.debug.print("elements in cell    {b}\n", .{cell[@divTrunc(i, 3)][@divTrunc(j, 3)]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
    stack.push(i,j,0b1000);
    grid[index] = @popCount(@as(u16,@intCast(0b1000))-1)+1;
    lines[i] |= 0b1000;
    columns[j] |= 0b1000;  
    cell[@divTrunc(i, 3)][@divTrunc(j, 3)] |= 0b1000;  
    std.debug.print("\n=> ***push executed***\n\n", .{});
    std.debug.print("===================\n   Changed Grid\n===================\n", .{});
    print();
    std.debug.print("\nelement ({},{}) = {}\n", .{i, j, grid[index]});
    std.debug.print("code pushed             {b}\n", .{0b1000});
    std.debug.print("elements in line   {b}\n", .{lines[2]});
    std.debug.print("elements in column  {b}\n", .{columns[0]});
    std.debug.print("elements in cell    {b}\n", .{cell[@divTrunc(i, 3)][@divTrunc(j, 3)]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
    const node = stack.pop();
    index = (node.i<<3) + node.i + node.j;
    grid[index] = 0;
    lines[i] &= ~@as(u16,@intCast(0b1000));
    columns[j] &= ~@as(u16,@intCast(0b1000));
    cell[@divTrunc(i, 3)][@divTrunc(j, 3)] &= ~@as(u16,@intCast(0b1000));
    std.debug.print("\n=> ***pop executed***\n\n", .{});
    std.debug.print("===================\n   Changed Grid\n===================\n", .{});
    print();
    std.debug.print("element ({},{}) = {}\n", 
        .{node.i, node.j, grid[index]}
    );
    std.debug.print("code poped              {b}\n", .{node.code});
    std.debug.print("elements in line   {b}\n", .{lines[node.i]});
    std.debug.print("elements in column  {b}\n", .{columns[node.j]});
    std.debug.print("elements in cell    {b}\n", .{cell[@divTrunc(i, 3)][@divTrunc(j, 3)]});
    std.debug.print("stack size    {}\n", .{ stack.size() });
}

pub fn solve() void {
   var node : *StkNode = undefined;       //
   var code : u16 = 1;                    // binary code for candidate
   var inserted : u16 = undefined;        // occupation set
   var j : u16 = 0;                       //
   var i : u16 = 0;                       //
   var li : u16 = lines[0];               // occupation sets of a line
   var ci : [*]u16 = cell[0];             // occupation sets of a cell line
   var c : u8 = undefined;                // candidate in {0,1,2,3,4,5,6,7,8,9} 
   var index : u16 = 0;                   // index in the grid
   //@breakpoint();
   @prefetch(&grid[index], .{.rw = .read, .locality = 0, .cache = .data});
   while (true) {
      c = grid[index];
      if ( c == 0 ) {                     // jump over non empty elements
        // "inserted" is the occupation set, the inverse of the candidate set
        inserted = li|columns[j]|ci[@divTrunc(j, 3)];
        // if adding candidate with occupation set overflows -> no candidate
        if ( (inserted + code ) >= 512 ) {// backtrack if there isn't any candidate
          node = stack.pop();             // pop previous inserted i, j, and code
          i = node.i;
          j = node.j;
          index = @shlExact(i,3) + i + j;
          grid[index] = 0;                // erase previous value
          lines[i] &= ~node.code;
          li = lines[i];
          columns[j] &= ~node.code;
          ci = cell[@divTrunc(i, 3)];
          ci[@divTrunc(j, 3)] &= ~node.code;
          code = @shlExact(node.code, 1); // get next candidate
          continue;                       // short-circuits line by line logic
        }
        // chosen candidate is the next empty place in the occupation set
        code = @shrExact(((inserted + code ) ^ inserted) + code, 1);
        stack.push(i, j, code);           // store and save candidate
        grid[index] = @popCount(code-1)+1;
        lines[i] |= @truncate(code);
        li = lines[i];
        columns[j] |= @truncate(code);
        ci[@divTrunc(j, 3)] |= @intCast(code);
        code = 1;                         // next candidate starts with 1
      }
      index += 1;                         // advance to the next position in grid
      j += 1;                             // advance to the next column
      if ( j == 9 ) {                     // reached last element in the line
        if ( i == 8 ) break;              // reached last element -> exit
        j = 0;                            // starts with first element in the line
        i += 1;                           // go to the next line
        ci = cell[@divTrunc(i, 3)];       // update cell helper
        li = lines[i];                    // update lines helper
      }
      @prefetch(&grid[index], .{.rw = .read, .locality = 2, .cache = .data});
   }
   stack.reset();
}
