// src/main.zig
const std = @import("std");
const finder = @import("finder.zig");
const config = @import("config.zig");
const utils = @import("utils.zig");
const cli = @import("cli.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Parse command line arguments and build configuration
    var conf = try cli.parseArgs(allocator);
    defer conf.deinit();

    if (conf.showHelp) {
        try cli.printHelp();
        return;
    }

    if (conf.showVersion) {
        try cli.printVersion();
        return;
    }

    // Validate configuration
    try conf.validate();

    // Initialize path finder with configuration
    var path_finder = try finder.PathFinder.init(allocator, conf);
    defer path_finder.deinit();

    // Execute the search
    var results = try path_finder.search();
    defer results.deinit();

    // Output results
    try utils.outputResults(allocator, results, conf);
}
