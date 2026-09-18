const std = @import("std");
const linux = std.os.linux;
const epoch = std.time.epoch;

const print = std.debug.print;

fn posixCksum(bytes: []const u8) u32 {
    var crc: u32 = 0;

    for (bytes) |byte| {
        crc ^= @as(u32, byte) <<| 24;
        var bit: u4 = 0;
        while (bit < 8) : (bit += 1) {
            crc = if (crc & 0x80000000 != 0)
                (crc *% 2) ^ 0x04c11db7
            else
                crc *% 2;
        }
    }

    var length = bytes.len;
    while (length != 0) {
        const byte: u8 = @truncate(length);
        crc ^= @as(u32, byte) <<| 24;
        var bit: u4 = 0;
        while (bit < 8) : (bit += 1) {
            crc = if (crc & 0x80000000 != 0)
                (crc *% 2) ^ 0x04c11db7
            else
                crc *% 2;
        }
        length >>= 8;
    }

    return ~crc;
}

fn randomSuffix() u32 {
    var bytes: [4]u8 = undefined;
    if (linux.getrandom(&bytes, bytes.len, 0) != bytes.len) return 0;
    return posixCksum(&bytes);
}

pub fn main() void {
    var timestamp: linux.timespec = undefined;
    if (linux.clock_gettime(linux.CLOCK.REALTIME, &timestamp) != 0) {
        print("1000000001_00000_00000_00000000\n", .{});
        return;
    }

    const seconds: u64 = @intCast(timestamp.sec);
    const day = (epoch.EpochSeconds{ .secs = seconds }).getEpochDay();
    const year_day = day.calculateYearDay();
    const month_day = year_day.calculateMonthDay();
    const day_seconds = (epoch.EpochSeconds{ .secs = seconds }).getDaySeconds();
    const suffix = randomSuffix();

    print("{d:0>4}{d:0>2}{d:0>2}{d:0>2}{d:0>2}{d:0>2}_{d:0>5}_{d:0>5}_{x:0>8}\n", .{
        year_day.year,
        month_day.month.numeric(),
        month_day.day_index + 1,
        day_seconds.getHoursIntoDay(),
        day_seconds.getMinutesIntoHour(),
        day_seconds.getSecondsIntoMinute(),
        @as(u32, @intCast(linux.getpid())),
        @as(u32, @intCast(linux.getppid())),
        suffix,
    });
}
