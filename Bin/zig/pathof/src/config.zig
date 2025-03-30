// src/config.zig
const std = @import("std");
const utils = @import("utils.zig");

pub const SearchDirection = enum {
    up,
    down,
    both,
};

pub const SearchType = enum {
    file,
    dir,
    exe,
    all,
};

pub const SortType = enum {
    distance,
    name,
    path,
    time,
};

pub const OutputFormat = enum {
    plain,
    json,
    csv,
};

pub const Config = struct {
    allocator: std.mem.Allocator,

    // Search direction options
    direction: SearchDirection = .both,
    base_dir: []const u8,

    // Search type options
    search_type: SearchType = .all,

    // Matching behavior
    exact_match: bool = false,
    shallow_search: bool = false,
    case_sensitive: bool = false,
    fuzzy_match: bool = true,

    // Search depth control
    max_depth: u32 = 100,
    smart_search: bool = true,

    // Item specification
    patterns: std.ArrayList([]const u8),

    // Output control
    output_file: ?[]const u8 = null,
    print_to_stdout: bool = true,
    list_all: bool = false,
    result_limit: u32 = 50,
    sort_by: SortType = .distance,
    format: OutputFormat = .plain,

    // General options
    showHelp: bool = false,
    showVersion: bool = false,
    debug: bool = false,

    pub fn init(allocator: std.mem.Allocator) !Config {
        return Config{
            .allocator = allocator,
            .base_dir = try utils.getCurrentDir(allocator),
            .patterns = std.ArrayList([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *Config) void {
        self.allocator.free(self.base_dir);
        for (self.patterns.items) |pattern| {
            self.allocator.free(pattern);
        }
        self.patterns.deinit();
        if (self.output_file) |path| {
            self.allocator.free(path);
        }
    }

    pub fn validate(self: *Config) !void {
        // Check if base directory exists
        var dir = std.fs.openDirAbsolute(self.base_dir, .{}) catch |err| {
            std.debug.print("Error: Base directory '{s}' is invalid: {!}\n", .{ self.base_dir, err });
            return error.InvalidBaseDirectory;
        };
        dir.close();

        // Check if patterns are specified
        if (self.patterns.items.len == 0) {
            std.debug.print("Error: No search patterns specified\n", .{});
            return error.NoPatterns;
        }

        // Additional validations can be added here
    }

    // Determine if we should autodetect project root
    pub fn shouldDetectProjectRoot(self: Config) bool {
        return !self.shallow_search and self.direction != .down;
    }
};
