const std = @import("std");
const handler = @import("handler.zig");
const engine = @import("engine.zig");
const setting = @import("setting.zig");

// run is the single entry point for the CLI interface.
// It reads args, dispatches to the correct engine procedure,
// and writes the response body to stdout.
pub fn run(allocator: std.mem.Allocator) !void {
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // args[0] is the executable name; args[1] is the command
    if (args.len < 2) {
        return printUsage();
    }

    const cmd = handler.resolveCommand(args[1]) catch {
        return printUsage();
    };

    const s = setting.load(allocator);

    const rest = args[2..];

    const response = switch (cmd) {
        .health => try engine.fetchHealth(allocator, s),
        .stop => try engine.sendStop(allocator, s),
        .list => blk: {
            const params = try handler.resolveListParams(rest);
            break :blk try engine.fetchActions(allocator, s, params);
        },
        .get => blk: {
            const reference = try handler.resolveReference(rest);
            break :blk try engine.fetchAction(allocator, s, reference);
        },
        .push => blk: {
            const params = try handler.resolvePushParams(rest);
            break :blk try engine.pushAction(allocator, s, params);
        },
        .pop => blk: {
            const reference = try handler.resolveReference(rest);
            break :blk try engine.popAction(allocator, s, reference);
        },
    };
    defer allocator.free(response.body);

    const stdout = std.io.getStdOut().writer();
    try stdout.print("{s}\n", .{response.body});
}

// printUsage writes the command reference to stderr.
fn printUsage() void {
    const stderr = std.io.getStdErr().writer();
    stderr.writeAll(
        \\usage: actions-data-service-cli <command> [options]
        \\
        \\commands:
        \\  health
        \\  stop
        \\  list   [--skip=N] [--limit=N]
        \\  get    <reference>
        \\  push   --reference=  --name=  --description=  --type=
        \\         [--address=] [--selector=] [--value=]
        \\         [--script=] [--delay=N]
        \\  pop    <reference>
        \\
    ) catch {};
}
