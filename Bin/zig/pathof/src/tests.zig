// src/tests.zig
const std = @import("std");
const testing = std.testing;
const config = @import("config.zig");
const finder = @import("finder.zig");
const cli = @import("cli.zig");
const utils = @import("utils.zig");

test "config initialization" {
    const allocator = testing.allocator;
    var conf = try config.Config.init(allocator);
    defer conf.deinit();

    try testing.expect(conf.direction == .both);
    try testing.expect(conf.search_type == .all);
    try testing.expect(conf.fuzzy_match);
    try testing.expect(!conf.exact_match);
}

test "pattern matching basic" {
    var allocator = testing.allocator;
    var conf = try config.Config.init(allocator);
    defer conf.deinit();

    try conf.patterns.append(try allocator.dupe(u8, "test.txt"));

    var finder_instance = try finder.PathFinder.init(allocator, conf);
    defer finder_instance.deinit();

    try testing.expect(try finder_instance.isPatternMatch("test.txt"));
    try testing.expect(!try finder_instance.isPatternMatch("other.txt"));
}

test "pattern matching fuzzy" {
    var allocator = testing.allocator;
    var conf = try config.Config.init(allocator);
    defer conf.deinit();

    conf.fuzzy_match = true;
    try conf.patterns.append(try allocator.dupe(u8, "test"));

    var finder_instance = try finder.PathFinder.init(allocator, conf);
    defer finder_instance.deinit();

    try testing.expect(try finder_instance.isPatternMatch("test.txt"));
    try testing.expect(try finder_instance.isPatternMatch("testing.md"));
    try testing.expect(!try finder_instance.isPatternMatch("other.txt"));
}

test "pattern matching case sensitivity" {
    var allocator = testing.allocator;
    var conf = try config.Config.init(allocator);
    defer conf.deinit();

    conf.exact_match = true;
    try conf.patterns.append(try allocator.dupe(u8, "Test.txt"));

    var finder_instance = try finder.PathFinder.init(allocator, conf);
    defer finder_instance.deinit();

    // Default is case-insensitive
    try testing.expect(try finder_instance.isPatternMatch("test.txt"));

    // Enable case sensitivity
    conf.case_sensitive = true;
    try testing.expect(!try finder_instance.isPatternMatch("test.txt"));
    try testing.expect(try finder_instance.isPatternMatch("Test.txt"));
}

test "json escaping" {
    var allocator = testing.allocator;

    const original = "path/with \"quotes\" and \\backslashes\\";
    const escaped = try utils.escapeJsonString(allocator, original);
    defer allocator.free(escaped);

    try testing.expectEqualStrings("path/with \\\"quotes\\\" and \\\\backslashes\\\\", escaped);
}
