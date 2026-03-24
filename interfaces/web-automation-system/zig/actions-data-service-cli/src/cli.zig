const std = @import("std");
const handler = @import("handler.zig");
const engine = @import("engine.zig");
const setting = @import("setting.zig");
const help = @import("help.zig");

// run is the single entry point for the CLI interface.
// It reads args, dispatches to the correct engine procedure,
// and writes the response body to stdout.
//
pub fn run(allocator: std.mem.Allocator) !void {
    const arguments = try std.process.argsAlloc(allocator);

    defer std.process.argsFree(allocator, arguments);

    // args[0] is the executable name; args[1] is the command
    if (arguments.len < 2) {
        return help.printUsage();
    }

    // Handle global help and version flags
    if (std.mem.eql(u8, arguments[1], "--help") or std.mem.eql(u8, arguments[1], "-h")) {
        return help.printHelp();
    }

    if (std.mem.eql(u8, arguments[1], "--version") or std.mem.eql(u8, arguments[1], "-v")) {
        return help.printVersion();
    }

    const command = handler.resolveCommand(arguments[1]) catch {
        return help.printUsage();
    };

    const rest = arguments[2..];

    // Check for command-specific help
    if (help.checkForHelpFlag(rest)) {
        return help.printCommandHelp(command);
    }

    const allocated_setting = setting.load(allocator);

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
                    return error.InvalidOutputDirectory;
                };

                defer directory.close();

                var file = try directory.createFile(parameters.file_name, .{ .truncate = true });

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
                    return error.InvalidOutputDirectory;
                };

                defer directory.close();

                var file = try directory.createFile(parameters.file_name, .{ .truncate = true });

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

    std.debug.print("{s}\n", .{result.body});
}
