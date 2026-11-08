//~@ Libraries
//? Generic plumbing, nothing hook-specific. This is the part that moves to lib.zig later.
const lib = struct {
    const std = @import("std");

    //> Alias the std namespaces and functions used across the file.
    const mem = std.mem;
    const json = std.json;

    const print = std.debug.print;
    const exit = std.process.exit;
    const basename = std.fs.path.basename;
    const stdin = std.fs.File.stdin;
    const expect = std.testing.expect;

    const ArenaAllocator = std.heap.ArenaAllocator;
    const page_allocator = std.heap.page_allocator;

    //? Hook payloads are tiny; the cap only guards against runaway input.
    const max_input_bytes = 1024 * 1024;

    //? Exit code 2 is how the hook protocol signals "block this tool call".
    const exit_blocked = 2;

    //> Byte-string helpers, so call sites never repeat `u8`.
    fn eql(a: []const u8, b: []const u8) bool {
        return mem.eql(u8, a, b);
    }

    fn startsWith(haystack: []const u8, prefix: []const u8) bool {
        return mem.startsWith(u8, haystack, prefix);
    }

    fn endsWith(haystack: []const u8, suffix: []const u8) bool {
        return mem.endsWith(u8, haystack, suffix);
    }

    /// Reads the hook payload and returns `tool_input.command`.
    /// Fails open: any read, parse, or shape error yields null.
    //? Failing open is deliberate. Non-shell tools have no `command` field, and
    //? a parser bug must not block every tool call. Flip the `catch` arms and
    //? shape checks to fail closed if you would rather be strict.
    fn readHookCommand(allocator: mem.Allocator) ?[]const u8 {
        //> Read all of stdin, then parse it as JSON.
        const input = stdin().readToEndAlloc(allocator, max_input_bytes) catch return null;
        const parsed = json.parseFromSlice(json.Value, allocator, input, .{}) catch return null;

        //> Walk payload.tool_input.command, bailing out on any unexpected shape.
        const root = parsed.value;
        if (root != .object) return null;
        const tool_input = root.object.get("tool_input") orelse return null;
        if (tool_input != .object) return null;
        const command = tool_input.object.get("command") orelse return null;
        if (command != .string) return null;
        return command.string;
    }

    /// Prints the reason to stderr and exits with the block code.
    fn block(name: []const u8, reason: []const u8) noreturn {
        print("Blocked by {s}: {s}\n", .{ name, reason });
        exit(exit_blocked);
    }
};

//~@ Rules
//? Pure logic: no I/O, no allocation. This is the only section to edit when tuning the guard.
const rules = struct {
    const mem = lib.mem;
    const eql = lib.eql;
    const startsWith = lib.startsWith;
    const endsWith = lib.endsWith;
    const basename = lib.basename;

    const name = "codex-guard-destructive";
    const block_reason = "matched dangerous pattern";

    //? Segments are separate commands joined by ; | & or a newline. `rm` in one
    //? segment never pairs with a target in another.
    const segment_separators = ";|&\n";

    //? Quotes, parens and backticks are separators so that "$(rm -rf /)",
    //? `rm -rf /` and "/" all tokenize to the bare words inside them.
    const token_separators = " \t\"'()`";

    //? Compared after normalize(), so "/", "/*", "//" and "~/*" are all covered.
    //? The empty string is the filesystem root.
    const dangerous_targets = [_][]const u8{
        "",
        "~",
        "$HOME",
        "${HOME}",
        "/bin",
        "/boot",
        "/dev",
        "/etc",
        "/home",
        "/lib",
        "/opt",
        "/proc",
        "/root",
        "/sbin",
        "/sys",
        "/usr",
        "/var",
    };

    //? The only /dev target `dd` may write to safely.
    const safe_dd_target = "of=/dev/null";

    /// Strips a trailing `/*` and any trailing slashes: "/usr/*" -> "/usr", "/" -> "".
    fn normalize(token: []const u8) []const u8 {
        var trimmed = token;
        //> Drop a trailing glob first, then any run of slashes.
        if (endsWith(trimmed, "/*")) trimmed = trimmed[0 .. trimmed.len - 2];
        while (trimmed.len > 0 and trimmed[trimmed.len - 1] == '/') {
            trimmed = trimmed[0 .. trimmed.len - 1];
        }
        return trimmed;
    }

    fn isDangerousTarget(token: []const u8) bool {
        const target = normalize(token);
        for (dangerous_targets) |dangerous| {
            if (eql(target, dangerous)) return true;
        }
        return false;
    }

    fn isDangerousDdOutput(token: []const u8) bool {
        return startsWith(token, "of=/dev/") and !eql(token, safe_dd_target);
    }

    fn segmentIsDestructive(segment: []const u8) bool {
        var tokens = mem.tokenizeAny(u8, segment, token_separators);
        var seen_rm = false;
        var seen_dd = false;

        //> Scan tokens left to right, classifying each exactly once.
        while (tokens.next()) |token| {
            //? basename makes "/bin/rm" and "rm" equivalent.
            const command = basename(token);

            if (eql(command, "rm")) {
                seen_rm = true;
            } else if (eql(command, "dd")) {
                seen_dd = true;
            } else if (startsWith(command, "mkfs")) {
                //? Matches any token, so `echo mkfs` is blocked too. Harmless false positive.
                return true;
            } else if (seen_dd and isDangerousDdOutput(token)) {
                return true;
            } else if (seen_rm and isDangerousTarget(token)) {
                //? seen_rm is sticky for the segment: `rm foo /` blocks. Errs on the safe side.
                return true;
            }
        }
        return false;
    }

    fn isDestructive(command: []const u8) bool {
        //> Split into independent commands, and block if any one is destructive.
        var segments = mem.tokenizeAny(u8, command, segment_separators);
        while (segments.next()) |segment| {
            if (segmentIsDestructive(segment)) return true;
        }
        return false;
    }
};

//~@ Simulation
//> Test blocks must live at file scope; nested in a struct, zig test never finds them.
test "blocks destructive commands" {
    //? Root and home, in every spelling.
    try lib.expect(rules.isDestructive("rm -rf /"));
    try lib.expect(rules.isDestructive("rm -rf -- /"));
    try lib.expect(rules.isDestructive("rm -rf \"$HOME\""));
    try lib.expect(rules.isDestructive("rm -rf $HOME/"));
    try lib.expect(rules.isDestructive("rm -rf ~/*"));
    try lib.expect(rules.isDestructive("/bin/rm -rf ~"));
    try lib.expect(rules.isDestructive("rm -rf /usr"));

    //? Wrappers and chaining.
    try lib.expect(rules.isDestructive("sudo rm -rf /"));
    try lib.expect(rules.isDestructive("ls && rm -rf /*"));
    try lib.expect(rules.isDestructive("echo hi; rm -rf \"/\""));
    try lib.expect(rules.isDestructive("`rm -rf /`"));
    try lib.expect(rules.isDestructive("echo $(rm -rf /)"));

    //? Disk-level commands.
    try lib.expect(rules.isDestructive("dd if=/dev/zero of=/dev/sda"));
    try lib.expect(rules.isDestructive("mkfs.ext4 /dev/sda1"));
}

test "allows ordinary commands" {
    //> Mentioning a dangerous path is not deleting it.
    try lib.expect(!rules.isDestructive("ls -la /"));
    try lib.expect(!rules.isDestructive("echo rm -rf"));
    try lib.expect(!rules.isDestructive("rm file.txt; echo /"));

    //> Scoped deletes stay allowed.
    try lib.expect(!rules.isDestructive("rm -rf ./build"));
    try lib.expect(!rules.isDestructive("rm -rf /tmp/build"));
    try lib.expect(!rules.isDestructive("rm -rf /usr/local/share/old"));
    try lib.expect(!rules.isDestructive("rm -rf ~/projects/old"));

    //> Harmless dd.
    try lib.expect(!rules.isDestructive("dd if=a.img of=b.img"));
    try lib.expect(!rules.isDestructive("dd if=a.img of=/dev/null"));
}

//~@ Execution
pub fn main() void {
    //> Use an arena so everything is freed together on exit.
    var arena = lib.ArenaAllocator.init(lib.page_allocator);
    defer arena.deinit();

    //> Read the command, then block it if it matches a rule.
    const command = lib.readHookCommand(arena.allocator()) orelse return;
    if (rules.isDestructive(command)) lib.block(rules.name, rules.block_reason);
}
