const std = @import("std");
const os = std.os;

// Structure to hold SSH configuration
const SshConfig = struct {
    username: []const u8,
    host: []const u8,
    identityFile: []const u8,
};

// Function to read SSH configuration from a file
fn readSshConfig(allocator: std.mem.Allocator, filePath: []const u8) !?SshConfig {
    std.log.info("Reading SSH config from file: {s}", .{filePath}); // Debug: log the file path
    const file = try std.fs.openFile(filePath, .{ .read = true });
    defer file.close();

    const reader = file.reader();
    var buffer = std.ArrayList(u8).init(allocator);
    defer buffer.deinit();

    try buffer.appendSlice(try reader.readAllAlloc(allocator));

    const content = buffer.items();
    std.log.debug("File content:\n{s}", .{content}); // Debug: log the file content

    var config: SshConfig = undefined;
    var iter = std.mem.tokenize(content, "\n");
    while (iter.next()) |line| {
        std.log.debug("Processing line: {s}", .{line}); // Debug: log each line being processed

        if (std.mem.startsWith(line, "user = ")) {
            config.username = line[7..]; // Corrected index
            std.log.debug("Found username: {s}", .{config.username}); // Debug: log the username
        } else if (std.mem.startsWith(line, "email = ")) {
            // Email is not used for SSH config, skipping
            std.log.debug("Skipping email line.", .{}); // Debug: log skipping email
        } else if (std.mem.startsWith(line, "[core]")) {
            std.log.debug("Skipping [core] line.", .{});
            continue;
        } else if (std.mem.startsWith(line, "sshCommand = ")) {
            const start = std.mem.indexOf(u8, line, ".ssh/") orelse {
                std.log.warn("Could not find '.ssh/' in sshCommand: {s}", .{line}); // Debug: error finding .ssh/
                continue; // Skip to the next line
            };
            const end = std.mem.indexOf(u8, line, "\"") orelse {
                std.log.warn("Could not find '\"' in sshCommand: {s}", .{line}); // Debug: error finding "
                continue; // Skip to the next line
            };

            config.identityFile = line[start + 5 .. end]; // Extract identity file path
            config.host = filePath; // Using the file path for host
            std.log.debug("Found identityFile: {s}", .{config.identityFile}); // Debug: log the identityFile
            std.log.debug("Using filePath as host: {s}", .{config.host}); // Debug: log using filepath as host
        }
    }

    // Validation to ensure necessary fields are populated
    if (config.username == null or config.identityFile == null or config.host == null) {
        std.log.warn("Skipping file {s} because it does not contain all required data.", .{filePath});
        return null; // Not all required data was found
    }
    return config;
}

// Function to set up SSH configuration
fn setupSsh(sshConfig: SshConfig) !void {
    const sshConfigPath = try std.fmt.allocPrint(std.heap.page_allocator, "{s}{s}", .{ (try std.fs.homeDir().?.path.?), "/.ssh/config" });
    defer std.heap.page_allocator.free(sshConfigPath);

    var file = try std.fs.openFile(sshConfigPath, .{ .read = true, .create = true });
    defer file.close();

    var buffer = std.ArrayList(u8).init(std.heap.page_allocator);
    defer buffer.deinit();

    const configEntry = try std.fmt.allocPrint(std.heap.page_allocator,
        \\Host {s}
        \\    HostName github.com #FIXME
        \\    User {s}
        \\    IdentityFile {s}
        \\    IdentitiesOnly yes
    , .{ sshConfig.host, sshConfig.username, sshConfig.identityFile });
    defer std.heap.page_allocator.free(configEntry);

    const existingConfig = try file.reader().readAllAlloc(std.heap.page_allocator);
    defer std.heap.page_allocator.free(existingConfig);

    var newConfig = std.ArrayList(u8).init(std.heap.page_allocator);
    defer newConfig.deinit();

    if (std.mem.contains(existingConfig, configEntry)) {
        std.log.info("SSH config already exists for {s}. Skipping.", .{sshConfig.host});
        try newConfig.appendSlice(existingConfig); // Keep ExistingConfig
    } else {
        std.log.info("Adding SSH config for {s}...", .{sshConfig.host});
        try newConfig.appendSlice(existingConfig); //Prepend existingConfig
        try newConfig.appendSlice(configEntry); //Append SSH entry
    }

    const newConfigSlice = newConfig.toOwnedSlice();
    defer std.heap.page_allocator.free(newConfigSlice);

    try file.close(); //Close old reader

    // Open file in write mode and overwrite
    const writeFile = try std.fs.openFile(sshConfigPath, .{ .write = true, .truncate = true });
    defer writeFile.close();

    try writeFile.writer().writeAll(newConfigSlice);

    std.log.info("SSH configuration updated for {s} in {s}", .{ sshConfig.host, sshConfigPath });
}

// Function to process all config files in a directory
fn processDirectory(allocator: std.mem.Allocator, directoryPath: []const u8) !void {
    std.log.info("Processing directory: {s}", .{directoryPath}); // Debug: log the directory being processed
    const dir = try std.fs.openDir(directoryPath, .{});
    defer dir.close();

    var dir_iterator = dir.iterate();
    while (try dir_iterator.next()) |entry| {
        std.log.debug("Found entry: {s} (kind: {})", .{ entry.name, @tagName(entry.kind) }); // Debug: log each directory entry

        if (entry.kind == .File and std.mem.endsWith(entry.name, ".gitconfig")) {
            const filePath = try std.fmt.allocPrint(allocator, "{s}/{s}", .{ directoryPath, entry.name });
            defer allocator.free(filePath);

            const sshConfig = try readSshConfig(allocator, filePath) catch |err| {
                std.log.err("Error reading SSH config from {s}: {any}", .{ filePath, err });
                continue; // Skip to the next file
            };
            if (sshConfig) |config| {
                try setupSsh(config);
            } else {
                std.log.warn("Skipping file {s} because it does not contain the necessary configuration data.", .{filePath});
            }
        }
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer if (gpa.deinit()) {
        std.log.err("Allocator failed to deinit!", .{});
    };

    //Default path
    const default_path: []const u8 = "/Configuration/git/home";

    // Get the DOTS environment variable
    const dots_env = os.environ.get("DOTS");

    // Check if the DOTS environment variable is present
    const dotsPath = if (dots_env) |dots| {
        // If DOTS is set, combine it with the default path
        try std.fmt.allocPrint(allocator, "{s}{s}", .{ dots, default_path });
    } else {
        // If DOTS is not set, use a default path in current directory
        try std.fmt.allocPrint(allocator, ".{s}", .{default_path});
    };
    defer allocator.free(dotsPath);

    std.log.info("Starting SSH configuration with directory: {s}", .{dotsPath}); // Log starting directory

    try processDirectory(allocator, dotsPath);

    std.log.info("SSH configuration complete.", .{});
}
