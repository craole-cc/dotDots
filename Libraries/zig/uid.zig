const std = @import("std");

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();

    const pid = std.os.linux.getpid();
    const ppid = std.os.linux.getppid();

    var seed: u64 = undefined;
    try std.posix.getRandom(std.mem.asBytes(&seed));
    var prng = std.rand.DefaultPrng.init(seed);
    const rand_val = prng.random().int(u32);

    try stdout.print("PID: {d} | PPID: {d} | Hex: {x:0>8}\n", .{ pid, ppid, rand_val });
}
