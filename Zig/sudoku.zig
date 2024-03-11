const std = @import("std");
const grid = @import("grid.zig");

pub fn main() !void {
    // Get allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Parse args into string array (error union needs 'try')
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if ((args.len > 1) and (args[1].len == 81)) {
       grid.set(args[1]);
    }
    else {
       grid.set("800000000003600000070090200050007000000045700000100030001000068008500010090000400");
    }
    std.debug.print("\n===================\n    Input Grid\n===================\n", .{});
    grid.print();
    var timer = try std.time.Timer.start();
    grid.solve();
    const time_0 : u64 = timer.read();
    std.debug.print("\n===================\n     Solution\n===================\n", .{});
    grid.print();
    @setFloatMode(.Optimized);
    const ftime =  @as(f64,@floatFromInt(time_0))/1000000.0;
    std.debug.print("\ntime in milliseconds: {d:.5}", .{ftime} );
}