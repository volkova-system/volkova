const std = @import("std");
const handler = @import("handler.zig");
const engine = @import("engine.zig");
const setting = @import("setting.zig");

// run is the single entry point for the CLI interface.
// It reads args, dispatches to the correct engine procedure,
// and writes the response body to stdout.
//
pub fn run(allocator: std.mem.Allocator) !void {
    const arguments = try std.process.argsAlloc(allocator);

    defer std.process.argsFree(allocator, arguments);

    // args[0] is the executable name; args[1] is the command
    if (arguments.len < 2) {
        return printUsage();
    }

    const command = handler.resolveCommand(arguments[1]) catch {
        return printUsage();
    };

    const allocated_setting = setting.load(allocator);

    const rest = arguments[2..];

    var result: engine.Response = undefined;
    switch (command) {
        .health => {
            result = try engine.fetchHealth(allocator, allocated_setting);
        },
        .stop => {
            result = try engine.sendStop(allocator, allocated_setting);
        },
        .list => {
            const parameters = try handler.resolveListParameters(rest);

            const response = try engine.fetchActions(allocator, allocated_setting, parameters);

            if (parameters.output_directory) |directory_value| {
                var directory = std.fs.openDirAbsolute(directory_value, .{}) catch std.fs.cwd().openDir(directory_value, .{}) catch {
                    return error.InvalidOutputDir;
                };

                defer directory.close();

                var file_name_buffer: [256]u8 = undefined;
                const file_name = std.fmt.bufPrint(
                    &file_name_buffer,
                    "actions-{d}-{d}.json",
                    .{ parameters.skip, parameters.limit },
                ) catch "actions.json";

                var file = try directory.createFile(file_name, .{ .truncate = true });

                defer file.close();

                try file.writeAll(response.body);
            }

            result = response;
        },
        .get => {
            const parameters = try handler.resolveGetParameters(rest);

            const response = try engine.fetchAction(allocator, allocated_setting, parameters.reference);

            const action = response.body;

            if (parameters.output_directory) |directory_value| {
                var directory = std.fs.openDirAbsolute(directory_value, .{}) catch std.fs.cwd().openDir(directory_value, .{}) catch {
                    return error.InvalidOutputDir;
                };

                defer directory.close();

                var file_name_buffer: [256]u8 = undefined;
                const file_name = std.fmt.bufPrint(&file_name_buffer, "action-{s}.json", .{parameters.reference}) catch "action.json";

                var file = try directory.createFile(file_name, .{ .truncate = true });

                defer file.close();

                try file.writeAll(action);
            }

            result = response;
        },
        .push => {
            const parameters = try handler.resolvePushParameters(allocator, rest);

            result = try engine.pushAction(allocator, allocated_setting, parameters);
        },
        .pop => {
            const reference = try handler.resolveReference(rest);

            result = try engine.popAction(allocator, allocated_setting, reference);
        },
    }

    defer allocator.free(result.body);

    const stdout = std.io.getStdOut().writer();

    try stdout.print("{s}\n", .{result.body});
}

// printUsage writes the command reference to stderr.
//
fn printUsage() void {
    const stderr = std.io.getStdErr().writer();

    stderr.writeAll(
        \\usage: actions-data-service-cli <command> [options]
        \\
        \\commands:
        \\  health
        \\  stop
        \\  list   [--skip=N] [--limit=N] [--output=DIR]
        \\  get    <reference> [--output=DIR]
        \\  push   --action=FILE
        \\         | --reference=  --name=  --description=  --type=
        \\           [--address=] [--selector=] [--value=] [--script=] [--delay=N]
        \\  pop    <reference>
        \\
    ) catch {};
}
