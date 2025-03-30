// src/finder.zig
const std = @import("std");
const config = @import("config.zig");
const utils = @import("utils.zig");

pub const SearchResult = struct {
    path: []const u8,
    distance: u32,
    is_dir: bool,
    timestamp: i64,

    pub fn deinit(self: *SearchResult, allocator: std.mem.Allocator) void {
        allocator.free(self.path);
    }
};

pub const SearchResults = struct {
    allocator: std.mem.Allocator,
    items: std.ArrayList(SearchResult),

    pub fn init(allocator: std.mem.Allocator) SearchResults {
        return SearchResults{
            .allocator = allocator,
            .items = std.ArrayList(SearchResult).init(allocator),
        };
    }

    pub fn deinit(self: *SearchResults) void {
        for (self.items.items) |*result| {
            result.deinit(self.allocator);
        }
        self.items.deinit();
    }

    pub fn sort(self: *SearchResults, sort_type: config.SortType) void {
        const Context = struct {
            sort_type: config.SortType,

            pub fn lessThan(ctx: @This(), a: SearchResult, b: SearchResult) bool {
                return switch (ctx.sort_type) {
                    .distance => a.distance < b.distance,
                    .name => std.mem.lessThan(u8, std.fs.path.basename(a.path), std.fs.path.basename(b.path)),
                    .path => std.mem.lessThan(u8, a.path, b.path),
                    .time => a.timestamp > b.timestamp, // Newer files first
                };
            }
        };

        std.sort.insertion(SearchResult, self.items.items, Context{ .sort_type = sort_type }, Context.lessThan);
    }
};

pub const ProjectRootMarkers = [_][]const u8{
    ".git",
    "flake.nix",
    "package.json",
    "Cargo.toml",
    "go.mod",
    "CMakeLists.txt",
    "Makefile",
    ".project",
    "pubspec.yaml",
    "pyproject.toml",
    "setup.py",
    "pom.xml",
    "build.gradle",
};

pub const PathFinder = struct {
    allocator: std.mem.Allocator,
    conf: config.Config,
    project_root: ?[]const u8,

    pub fn init(allocator: std.mem.Allocator, conf: config.Config) !PathFinder {
        var finder = PathFinder{
            .allocator = allocator,
            .conf = conf,
            .project_root = null,
        };

        if (conf.shouldDetectProjectRoot()) {
            finder.project_root = try finder.detectProjectRoot();
            if (finder.project_root != null and finder.conf.debug) {
                std.debug.print("Detected project root: {s}\n", .{finder.project_root.?});
            }
        }

        return finder;
    }

    pub fn deinit(self: *PathFinder) void {
        if (self.project_root) |root| {
            self.allocator.free(root);
        }
    }

    pub fn search(self: *PathFinder) !SearchResults {
        var results = SearchResults.init(self.allocator);

        // Determine start directory
        const start_dir = if (self.project_root != null and !self.conf.shallow_search)
            self.project_root.?
        else
            self.conf.base_dir;

        // First search PATH if looking for executables
        if (self.conf.search_type == .exe) {
            try self.searchInPath(&results);
        }

        // Then search in filesystem
        switch (self.conf.direction) {
            .up => try self.searchUp(start_dir, &results),
            .down => try self.searchDown(start_dir, &results),
            .both => {
                try self.searchDown(start_dir, &results);
                try self.searchUp(start_dir, &results);
            },
        }

        // Sort results
        results.sort(self.conf.sort_by);

        return results;
    }

    fn detectProjectRoot(self: *PathFinder) !?[]const u8 {
        var current_dir = try self.allocator.dupe(u8, self.conf.base_dir);
        errdefer self.allocator.free(current_dir);

        var depth: u32 = 0;
        while (depth < self.conf.max_depth) : (depth += 1) {
            // Check for project markers
            for (ProjectRootMarkers) |marker| {
                const marker_path = try std.fs.path.join(self.allocator, &[_][]const u8{ current_dir, marker });
                defer self.allocator.free(marker_path);

                const file = std.fs.openFileAbsolute(marker_path, .{}) catch |err| {
                    if (err == error.FileNotFound) {
                        continue;
                    }
                    return err;
                };
                file.close();

                // Found a marker, return this directory
                return current_dir;
            }

            // Move up one directory level
            const parent_dir = std.fs.path.dirname(current_dir);
            if (parent_dir == null or std.mem.eql(u8, parent_dir.?, current_dir)) {
                // We've reached the root directory
                self.allocator.free(current_dir);
                return null;
            }

            self.allocator.free(current_dir);
            current_dir = try self.allocator.dupe(u8, parent_dir.?);
        }

        self.allocator.free(current_dir);
        return null;
    }

    fn searchInPath(self: *PathFinder, results: *SearchResults) !void {
        if (self.conf.search_type != .exe) return;

        const path_env = std.process.getEnvVarOwned(self.allocator, "PATH") catch return;
        defer self.allocator.free(path_env);

        var path_it = std.mem.tokenizeAny(u8, path_env, ":");

        while (path_it.next()) |path| {
            var dir = std.fs.openDirAbsolute(path, .{ .iterate = true }) catch continue;
            defer dir.close();

            var it = dir.iterate();
            while (try it.next()) |entry| {
                if (entry.kind != .file) continue;

                const is_match = try self.isPatternMatch(entry.name);
                if (!is_match) continue;

                // Check if file is executable
                const full_path = try std.fs.path.join(self.allocator, &[_][]const u8{ path, entry.name });

                const file = std.fs.openFileAbsolute(full_path, .{}) catch {
                    self.allocator.free(full_path);
                    continue;
                };
                defer file.close();

                const stat = try file.stat();
                const is_exec = ((stat.mode & 0o100) != 0);

                if (is_exec) {
                    try results.items.append(SearchResult{
                        .path = full_path,
                        .distance = 0, // PATH exes are considered distance 0
                        .is_dir = false,
                        .timestamp = @as(i64, @intCast(stat.mtime)),
                    });
                } else {
                    self.allocator.free(full_path);
                }
            }
        }
    }

    fn searchUp(self: *PathFinder, start_dir: []const u8, results: *SearchResults) !void {
        var current_dir = try self.allocator.dupe(u8, start_dir);
        defer self.allocator.free(current_dir);

        var depth: u32 = 0;
        while (depth < self.conf.max_depth) : (depth += 1) {
            try self.searchInDir(current_dir, depth, results);

            // Move up one directory level
            const parent_dir = std.fs.path.dirname(current_dir); // Remove the try
            if (parent_dir == null or std.mem.eql(u8, parent_dir.?, current_dir)) {
                // We've reached the root directory
                break;
            }

            const new_dir = try self.allocator.dupe(u8, parent_dir.?);
            self.allocator.free(current_dir);
            current_dir = new_dir;
        }
    }

    fn searchDown(self: *PathFinder, start_dir: []const u8, results: *SearchResults) !void {
        var queue = std.ArrayList(struct {
            path: []const u8,
            depth: u32,
        }).init(self.allocator);
        defer {
            for (queue.items) |item| {
                self.allocator.free(item.path);
            }
            queue.deinit();
        }

        try queue.append(.{
            .path = try self.allocator.dupe(u8, start_dir),
            .depth = 0,
        });

        while (queue.items.len > 0) {
            const item = queue.orderedRemove(0);
            const dir_path = item.path;
            const depth = item.depth;

            defer self.allocator.free(dir_path);

            try self.searchInDir(dir_path, depth, results);

            if (depth < self.conf.max_depth) {
                var dir = std.fs.openDirAbsolute(dir_path, .{ .iterate = true }) catch continue;
                defer dir.close();

                var it = dir.iterate();
                while (try it.next()) |entry| {
                    if (entry.kind != .directory) continue;

                    const subdir_path = try std.fs.path.join(self.allocator, &[_][]const u8{ dir_path, entry.name });
                    try queue.append(.{
                        .path = subdir_path,
                        .depth = depth + 1,
                    });
                }
            }
        }
    }

    fn searchInDir(self: *PathFinder, dir_path: []const u8, depth: u32, results: *SearchResults) !void {
        var dir = std.fs.openDirAbsolute(dir_path, .{ .iterate = true }) catch return;
        defer dir.close();

        var it = dir.iterate();
        while (try it.next()) |entry| {
            const is_dir = entry.kind == .directory;

            // Skip if we're only looking for a specific type
            if (self.conf.search_type == .file and is_dir) continue;
            if (self.conf.search_type == .dir and !is_dir) continue;

            const is_match = try self.isPatternMatch(entry.name);
            if (!is_match) continue;

            const full_path = try std.fs.path.join(self.allocator, &[_][]const u8{ dir_path, entry.name });

            // Check if file is executable when search_type is exe
            var should_include = true;
            var timestamp: i64 = 0;

            if (self.conf.search_type == .exe and !is_dir) {
                const file = std.fs.openFileAbsolute(full_path, .{}) catch {
                    self.allocator.free(full_path);
                    continue;
                };
                defer file.close();

                const stat = try file.stat();
                // should_include = (stat.mode & std.os.S.IXUSR) != 0;
                should_include = ((stat.mode & 0o100) != 0);
                timestamp = @as(i64, @intCast(stat.mtime));
            }

            if (should_include) {
                try results.items.append(SearchResult{
                    .path = full_path,
                    .distance = depth,
                    .is_dir = is_dir,
                    .timestamp = timestamp,
                });
            } else {
                self.allocator.free(full_path);
            }
        }
    }

    fn isPatternMatch(self: *PathFinder, filename: []const u8) !bool {
        for (self.conf.patterns.items) |pattern| {
            if (self.conf.exact_match) {
                if (self.conf.case_sensitive) {
                    if (std.mem.eql(u8, filename, pattern)) return true;
                } else {
                    if (std.ascii.eqlIgnoreCase(filename, pattern)) return true;
                }
            } else {
                // For fuzzy matching, let's use a simple substring check first
                // A more sophisticated fuzzy matching algorithm would be implemented here
                if (self.conf.fuzzy_match) {
                    if (self.conf.case_sensitive) {
                        if (std.mem.indexOf(u8, filename, pattern) != null) return true;
                    } else {
                        // This is a simplified case-insensitive check
                        const lower_filename = try std.ascii.allocLowerString(self.allocator, filename);
                        defer self.allocator.free(lower_filename);

                        const lower_pattern = try std.ascii.allocLowerString(self.allocator, pattern);
                        defer self.allocator.free(lower_pattern);

                        if (std.mem.indexOf(u8, lower_filename, lower_pattern) != null) return true;
                    }
                } else {
                    // Check for glob patterns
                    if (std.mem.indexOf(u8, pattern, "*") != null or std.mem.indexOf(u8, pattern, "?") != null) {
                        // Simple glob matching implementation would go here
                        // For now, let's just do a startsWith check if the pattern ends with *
                        if (std.mem.endsWith(u8, pattern, "*")) {
                            const prefix = pattern[0 .. pattern.len - 1];
                            if (self.conf.case_sensitive) {
                                if (std.mem.startsWith(u8, filename, prefix)) return true;
                            } else {
                                if (std.ascii.startsWithIgnoreCase(filename, prefix)) return true;
                            }
                        }
                    }
                }
            }
        }

        return false;
    }
};
