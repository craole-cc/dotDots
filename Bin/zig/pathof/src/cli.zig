// src/cli.zig
const std = @import("std");
const config = @import("config.zig");

const VERSION = "1.0.0";

pub fn parseArgs(allocator: std.mem.Allocator) !config.Config {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var conf = try config.Config.init(allocator);
    errdefer conf.deinit();

    if (args.len <= 1) {
        conf.showHelp = true;
        return conf;
    }

    var i: usize = 1;
    while (i < args.len) : (i += 1) {
        const arg = args[i];

        if (std.mem.eql(u8, arg, "--help") or std.mem.eql(u8, arg, "-h")) {
            conf.showHelp = true;
            return conf;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "-v")) {
            conf.showVersion = true;
            return conf;
        } else if (std.mem.eql(u8, arg, "--debug") or std.mem.eql(u8, arg, "-V")) {
            conf.debug = true;
        }
        // Search direction options
        else if (std.mem.eql(u8, arg, "--up")) {
            conf.direction = .up;
        } else if (std.mem.eql(u8, arg, "--down")) {
            conf.direction = .down;
        } else if (std.mem.eql(u8, arg, "--both")) {
            conf.direction = .both;
        } else if (std.mem.eql(u8, arg, "--direction") or std.mem.eql(u8, arg, "-d")) {
            i += 1;
            if (i >= args.len) return error.MissingDirectionValue;

            if (std.mem.eql(u8, args[i], "up")) {
                conf.direction = .up;
            } else if (std.mem.eql(u8, args[i], "down")) {
                conf.direction = .down;
            } else if (std.mem.eql(u8, args[i], "both")) {
                conf.direction = .both;
            } else {
                return error.InvalidDirectionValue;
            }
        } else if (std.mem.eql(u8, arg, "--base") or std.mem.eql(u8, arg, "-b")) {
            i += 1;
            if (i >= args.len) return error.MissingBaseValue;

            allocator.free(conf.base_dir);
            conf.base_dir = try allocator.dupe(u8, args[i]);
        }
        // Search type options
        else if (std.mem.eql(u8, arg, "--exe")) {
            conf.search_type = .exe;
        } else if (std.mem.eql(u8, arg, "--all")) {
            conf.search_type = .all;
        } else if (std.mem.eql(u8, arg, "--type")) {
            i += 1;
            if (i >= args.len) return error.MissingTypeValue;

            if (std.mem.eql(u8, args[i], "file")) {
                conf.search_type = .file;
            } else if (std.mem.eql(u8, args[i], "dir")) {
                conf.search_type = .dir;
            } else if (std.mem.eql(u8, args[i], "exe")) {
                conf.search_type = .exe;
            } else if (std.mem.eql(u8, args[i], "all")) {
                conf.search_type = .all;
            } else {
                return error.InvalidTypeValue;
            }
        }
        // Matching behavior
        else if (std.mem.eql(u8, arg, "--exact") or std.mem.eql(u8, arg, "-e")) {
            conf.exact_match = true;
            conf.fuzzy_match = false;
        } else if (std.mem.eql(u8, arg, "--shallow")) {
            conf.shallow_search = true;
        } else if (std.mem.eql(u8, arg, "--case-sensitive")) {
            conf.case_sensitive = true;
        } else if (std.mem.eql(u8, arg, "--fuzzy")) {
            conf.fuzzy_match = true;
        } else if (std.mem.eql(u8, arg, "--no-fuzzy")) {
            conf.fuzzy_match = false;
        }
        // Search depth control
        else if (std.mem.eql(u8, arg, "--max-depth")) {
            i += 1;
            if (i >= args.len) return error.MissingMaxDepthValue;

            const depth = try std.fmt.parseInt(u32, args[i], 10);
            conf.max_depth = depth;
        } else if (std.mem.eql(u8, arg, "--smart") or std.mem.eql(u8, arg, "--deep")) {
            conf.smart_search = true;
        } else if (std.mem.eql(u8, arg, "--no-smart")) {
            conf.smart_search = false;
        }
        // Item specification
        else if (std.mem.eql(u8, arg, "--item") or std.mem.eql(u8, arg, "-i")) {
            i += 1;
            if (i >= args.len) return error.MissingItemValue;

            const pattern = try allocator.dupe(u8, args[i]);
            try conf.patterns.append(pattern);
        }
        // Output control
        else if (std.mem.eql(u8, arg, "--output") or std.mem.eql(u8, arg, "-o")) {
            i += 1;
            if (i >= args.len) return error.MissingOutputValue;

            if (conf.output_file) |path| {
                allocator.free(path);
            }
            conf.output_file = try allocator.dupe(u8, args[i]);
            conf.print_to_stdout = false;
        } else if (std.mem.eql(u8, arg, "--print") or std.mem.eql(u8, arg, "-p")) {
            conf.print_to_stdout = true;
        } else if (std.mem.eql(u8, arg, "--list") or std.mem.eql(u8, arg, "-l")) {
            conf.list_all = true;
        } else if (std.mem.eql(u8, arg, "--limit")) {
            i += 1;
            if (i >= args.len) return error.MissingLimitValue;

            const limit = try std.fmt.parseInt(u32, args[i], 10);
            conf.result_limit = limit;
        } else if (std.mem.eql(u8, arg, "--sort")) {
            i += 1;
            if (i >= args.len) return error.MissingSortValue;

            if (std.mem.eql(u8, args[i], "distance")) {
                conf.sort_by = .distance;
            } else if (std.mem.eql(u8, args[i], "name")) {
                conf.sort_by = .name;
            } else if (std.mem.eql(u8, args[i], "path")) {
                conf.sort_by = .path;
            } else if (std.mem.eql(u8, args[i], "time")) {
                conf.sort_by = .time;
            } else {
                return error.InvalidSortValue;
            }
        } else if (std.mem.eql(u8, arg, "--format")) {
            i += 1;
            if (i >= args.len) return error.MissingFormatValue;

            if (std.mem.eql(u8, args[i], "plain")) {
                conf.format = .plain;
            } else if (std.mem.eql(u8, args[i], "json")) {
                conf.format = .json;
            } else if (std.mem.eql(u8, args[i], "csv")) {
                conf.format = .csv;
            } else {
                return error.InvalidFormatValue;
            }
        } else {
            // If not a flag, assume it's a pattern
            const pattern = try allocator.dupe(u8, arg);
            try conf.patterns.append(pattern);
        }
    }

    return conf;
}

pub fn printHelp() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print(
        \\pathof - Intelligent Path Finder
        \\
        \\USAGE:
        \\  pathof [OPTIONS] [PATTERN]
        \\
        \\DESCRIPTION:
        \\  Recursively searches for files, directories or executables in parent
        \\  or child directories. Provides smart detection of project roots and
        \\  executables in PATH.
        \\
        \\SEARCH DIRECTION OPTIONS:
        \\  --up                Search in parent directories only
        \\  --down              Search in child directories only
        \\  --both              Search in both directions (default: smart detection)
        \\  -d, --direction DIR Specify search direction (up|down|both)
        \\  -b, --base PATH     Starting directory for search (default: current directory)
        \\
        \\SEARCH TYPE OPTIONS:
        \\  --exe               Search for executables in PATH and directories
        \\  --all               Search for all file types (default)
        \\  --type TYPE         Specify type to search for (file|dir|exe|all)
        \\
        \\MATCHING BEHAVIOR:
        \\  -e, --exact         Use exact name matching (disables fuzzy matching)
        \\  --shallow           Combine exact matching with non-extensive search
        \\  --case-sensitive    Enable case-sensitive search
        \\  --fuzzy             Enable fuzzy name matching (default)
        \\  --no-fuzzy          Disable fuzzy name matching
        \\
        \\SEARCH DEPTH CONTROL:
        \\  --max-depth NUM     Limit search depth (default: 100)
        \\  --smart, --deep     Perform extensive search for executables (default)
        \\  --no-smart          Disable extensive executable search
        \\
        \\ITEM SPECIFICATION:
        \\  -i, --item PATTERN  File pattern to search for (can be used multiple times)
        \\                      Without this flag, the pattern is set to the last argument(s)
        \\
        \\OUTPUT CONTROL:
        \\  -o, --output FILE   Output search results to file (default: stdout)
        \\  -p, --print         Print search results to stdout
        \\  -l, --list          Return all matching results instead of just the closest
        \\  --limit NUM         Limit number of results when using --list (default: 50)
        \\  --sort TYPE         Sort results by (distance|name|path|time) (default: distance)
        \\  --format FORMAT     Output format (plain|json|csv) (default: plain)
        \\
        \\GENERAL OPTIONS:
        \\  -h, --help          Show this help message
        \\  -v, --version       Show version information
        \\  -V, --debug         Enable debug output
        \\
        \\EXAMPLES:
        \\  # Find .gitignore in parent directories
        \\  pathof --up .gitignore
        \\
        \\  # Search for index.html under /tmp
        \\  pathof --down --base /tmp index.html
        \\
        \\  # Find closest executable named 'cargo'
        \\  pathof --exe --up cargo
        \\
        \\  # Find exact match for 'README.md' in current project
        \\  pathof --exact README.md
        \\
        \\  # Search for multiple items
        \\  pathof --item "*.js" --item "*.ts"
        \\
    , .{});
}

pub fn printVersion() !void {
    const stdout = std.io.getStdOut().writer();
    try stdout.print("pathof version {s}\n", .{VERSION});
}
