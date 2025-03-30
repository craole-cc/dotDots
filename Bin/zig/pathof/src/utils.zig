// src/utils.zig
const std = @import("std");
const config = @import("config.zig");
const finder = @import("finder.zig");

pub fn getCurrentDir(allocator: std.mem.Allocator) ![]const u8 {
    var buf: [std.fs.max_path_bytes]u8 = undefined;
    // const path = try std.os.getcwd(&buf); // TODO: Not working
    const path = try std.posix.getcwd(&buf);
    return allocator.dupe(u8, path);
}

pub fn outputResults(allocator: std.mem.Allocator, results: finder.SearchResults, conf: config.Config) !void {
    if (results.items.items.len == 0) {
        std.debug.print("No matching items found.\n", .{});
        return error.NoMatchesFound;
    }

    var out_stream: std.fs.File.Writer = undefined;
    var file: ?std.fs.File = null;

    if (conf.output_file) |path| {
        file = try std.fs.createFileAbsolute(path, .{});
        out_stream = file.?.writer();
    } else if (conf.print_to_stdout) {
        out_stream = std.io.getStdOut().writer();
    } else {
        // If we're not outputting anywhere, just return
        return;
    }
    defer if (file) |f| f.close();

    switch (conf.format) {
        .plain => try outputPlainFormat(out_stream, results, conf),
        .json => try outputJsonFormat(allocator, out_stream, results, conf),
        .csv => try outputCsvFormat(out_stream, results, conf, allocator),
    }
}

fn outputPlainFormat(writer: std.fs.File.Writer, results: finder.SearchResults, conf: config.Config) !void {
    const limit = if (conf.list_all) conf.result_limit else 1;
    const count = @min(results.items.items.len, limit);

    for (results.items.items[0..count]) |result| {
        if (conf.list_all) {
            // Show more details in list mode
            try writer.print("{s} (distance: {}, type: {s})\n", .{
                result.path,
                result.distance,
                if (result.is_dir) "directory" else "file",
            });
        } else {
            // Just the path for single result
            try writer.print("{s}\n", .{result.path});
        }
    }
}

fn outputJsonFormat(allocator: std.mem.Allocator, writer: std.fs.File.Writer, results: finder.SearchResults, conf: config.Config) !void {
    const limit = if (conf.list_all) conf.result_limit else 1;
    const count = @min(results.items.items.len, limit);

    try writer.writeAll("{\n  \"results\": [\n");

    for (results.items.items[0..count], 0..) |result, i| {
        try writer.print("    {{\n      \"path\": \"{s}\",\n      \"distance\": {},\n      \"type\": \"{s}\"\n    }}", .{
            try escapeJsonString(allocator, result.path),
            result.distance,
            if (result.is_dir) "directory" else "file",
        });

        if (i < count - 1) {
            try writer.writeAll(",");
        }
        try writer.writeAll("\n");
    }

    try writer.writeAll("  ],\n");
    try writer.print("  \"count\": {}\n}}\n", .{count});
}

fn outputCsvFormat(writer: std.fs.File.Writer, results: finder.SearchResults, conf: config.Config, allocator: std.mem.Allocator) !void {
    const limit = if (conf.list_all) conf.result_limit else 1;
    const count = @min(results.items.items.len, limit);
    // Write header
    try writer.writeAll("path,distance,type\n");
    for (results.items.items[0..count]) |result| {
        const escaped_path = try escapeCsvString(allocator, result.path);
        defer allocator.free(escaped_path);

        try writer.print("\"{s}\",{},\"{s}\"\n", .{
            escaped_path,
            result.distance,
            if (result.is_dir) "directory" else "file",
        });
    }
}

fn escapeJsonString(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();

    for (input) |c| {
        switch (c) {
            '\\' => try output.appendSlice("\\\\"),
            '\"' => try output.appendSlice("\\\""),
            '\n' => try output.appendSlice("\\n"),
            '\r' => try output.appendSlice("\\r"),
            '\t' => try output.appendSlice("\\t"),
            else => try output.append(c),
        }
    }

    return output.toOwnedSlice();
}

fn escapeCsvString(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    errdefer output.deinit();

    var has_special = false;
    for (input) |c| {
        if (c == ',' or c == '"' or c == '\n' or c == '\r') {
            has_special = true;
        }

        if (c == '"') {
            try output.appendSlice("\"\"");
        } else {
            try output.append(c);
        }
    }

    if (has_special) {
        var result = try allocator.alloc(u8, output.items.len + 2);
        result[0] = '"';
        @memcpy(result[1 .. result.len - 1], output.items);
        result[result.len - 1] = '"';
        output.deinit();
        return result;
    }

    return output.toOwnedSlice();
}
