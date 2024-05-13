const stdout = bw.writer();
const std = @import("std");
const math = std.math;
const sqrt = math.complex.sqrt;
const RndGen = std.rand.DefaultPrng;
const print = std.debug.print;

var bw = std.io.bufferedWriter(stdout_file);
const stdout_file = std.io.getStdOut().writer();

const width: u8 = 100;
const height: u8 = 100;

var list: [height][width]f32 = undefined;
var diff_list: [height][width]f32 = undefined;
const levels: []const u8 = " ._=coaA@#";
const alpha = 0.028;
// const alpha_m = 0.147;
const b1: f32 = 0.278;
const b2: f32 = 0.365;
const d1: f32 = 0.267;
const d2: f32 = 0.445;
const dt: f32 = 0.05;

const ra: i16 = 21;

fn random_grid() !void {
    var rnd = RndGen.init(blk: {
        var seed: u64 = undefined;
        try std.posix.getrandom(std.mem.asBytes(&seed));
        break :blk seed;
    });

    for (0..height) |y| {
        for (0..width / 3) |x| {
            list[y][x] = rnd.random().float(f32);
        }
    }
}

fn display_grid(comptime H: usize, comptime W: usize, array_2d: [H][W]f32) !void {
    for (0..H) |y| {
        for (0..W) |x| {
            const c = levels[@as(usize, @intFromFloat(array_2d[y][x] * (levels.len)))];
            try stdout.print("{c}{c}", .{ c, c });
        }
        try stdout.print("{s}", .{"\n"});
    }
    try bw.flush();
}

fn emod(a: i16, b: i16) i16 {
    return @mod(@mod(a, b + b), b);
}

fn sigma_1(x: f32, a: f32) f32 {
    return 1 / (1.0 + math.exp(-(x - a) * 4 / alpha));
}

fn sigma_2(x: f32, a: f32, b: f32) f32 {
    return sigma_1(x, a) * (1 - sigma_1(x, b));
}

fn sigma_m(x: f32, y: f32, m: f32) f32 {
    return x * (1 - sigma_1(m, 0.5)) + y * sigma_1(m, 0.5);
}

fn s(n: f32, m: f32) f32 {
    return sigma_2(n, sigma_m(b1, d1, m), sigma_m(b2, d2, m));
}

fn compute_grid_diff() void {
    var cy: i16 = 0;
    while (cy < height) : (cy += 1) {
        var cx: i16 = 0;
        while (cx < width) : (cx += 1) {
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

            const q: f32 = s(n, m);
            diff_list[@as(usize, @intCast(cy))][@as(usize, @intCast(cx))] = (2 * q) - 1;
        }
    }
}

pub fn main() !void {

    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // const list = std.ArrayList(f32).init(allocator);
    // defer list.deinit();

    try random_grid();

    // print("\nm = {d}, n = {d}, s(n, m) = {d}\n", .{ m, n, s(n, m) });

    try display_grid(height, width, list);

    while (true) {
        compute_grid_diff();

        for (0..height) |y| {
            for (0..width) |x| {
                list[y][x] += dt * diff_list[y][x];
                list[y][x] = math.clamp(list[y][x], 0.0, 0.999);
            }
        }

        print("\n", .{});
        try display_grid(height, width, list);
    }

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
