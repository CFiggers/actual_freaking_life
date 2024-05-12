const stdout = bw.writer();
const std = @import("std");
const math = std.math;
const sqrt = math.complex.sqrt;
const RndGen = std.rand.DefaultPrng;
const print = std.debug.print;

var bw = std.io.bufferedWriter(stdout_file);
const stdout_file = std.io.getStdOut().writer();

const width: u8 = 100;
const height: u8 = 50;

var list: [height][width]f32 = undefined;
const levels: []const u8 = " ._=coaA@#";

const ra: i16 = 21;

fn random_grid() !void {
    var rnd = RndGen.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    for (0..height) |y| {
        for (0..width) |x| {
            list[y][x] = rnd.random().float(f32);
        }
    }
}

fn display_grid() !void {
    for (0..height) |y| {
        for (0..width) |x| {
            const c = levels[@as(usize, @intFromFloat(list[y][x] * (levels.len)))];
            try stdout.print("{c}", .{c});
        }
        try stdout.print("{s}", .{"\n"});
    }
}

fn emod(a: i16, b: i16) i16 {
    return @mod(@mod(a, b + b), b);
}

pub fn main() !void {

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // const list = std.ArrayList(f32).init(allocator);
    // defer list.deinit();

    try random_grid();

    const cx: i16 = 0;
    const cy: i16 = 0;
    var m: f32 = 0;
    var M: f32 = 0;
    var n: f32 = 0;
    var N: f32 = 0;
    const ri: f32 = ra / 3;

    var dy: i16 = -(ra - 1);
    while (dy < ra) : (dy += 1) {
        var dx: i16 = -(ra - 1);
        while (dx < ra) : (dx += 1) {
            const x: usize = @as(usize, @intCast(emod(cx + dx, width)));
            const y: usize = @as(usize, @intCast(emod(cy + dy, height)));

            if (dx * dx + dy * dy <= ri * ri) {
                m += list[y][x];
                M += 1;
            } else if (dx * dx + dy * dy <= ra * ra) {
                n += list[y][x];
                N += 1;
            }
        }
    }
    n /= N;
    m /= M;
    print("\nm = {d}, n = {d}\n", .{ m, n });
    // try display_grid();

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    // std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.

    // try stdout.print("Run `zig build test` to run the tests.\n", .{});

    // try bw.flush(); // don't forget to flush!
}

test "simple test" {
    //     var list = std.ArrayList(i32).init(std.testing.allocator);
    //     defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    //     try list.append(42);
    //     try std.testing.expectEqual(@as(i32, 42), list.pop());
}
