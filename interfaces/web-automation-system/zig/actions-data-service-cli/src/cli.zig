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

    // Handle global help and version flags
    if (std.mem.eql(u8, arguments[1], "--help") or std.mem.eql(u8, arguments[1], "-h")) {
        return printHelp();
    }

    if (std.mem.eql(u8, arguments[1], "--version") or std.mem.eql(u8, arguments[1], "-v")) {
        return printVersion();
    }

    const command = handler.resolveCommand(arguments[1]) catch {
        return printUsage();
    };

    const rest = arguments[2..];

    // Check for command-specific help
    if (handler.checkForHelpFlag(rest)) {
        return handler.printCommandHelp(command);
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

// printUsage writes a brief usage message to stderr.
//
fn printUsage() void {
    std.debug.print(
        \\actions-data-service-cli - Web automation actions data service CLI
        \\
        \\Usage:
        \\  actions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'actions-data-service-cli --help' for more information.
        \\
    , .{});
}

// printHelp writes the full help message to stdout.
//
fn printHelp() void {
    std.debug.print(
        \\actions-data-service-cli - Web automation actions data service CLI
        \\
        \\Usage:
        \\  actions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  list          List actions with optional filtering
        \\  get           Get a specific action by reference
        \\  push          Push a new action to the service
        \\  pop           Remove an action by reference
        \\
        \\Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N actions (default: 0)
        \\    --limit=N      Limit to N actions (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --action=FILE  Load action from JSON file
        \\    OR specify inline:
        \\    --reference=   Action reference (required)
        \\    --name=        Action name (required)
        \\    --description= Action description (required)
        \\    --type=        Action type (required)
        \\    --address=     Target address (optional)
        \\    --selector=    Element selector (optional)
        \\    --value=       Input value (optional)
        \\    --script=      Script to execute (optional)
        \\    --delay=N      Delay in milliseconds (optional)
        \\
        \\Examples:
        \\  actions-data-service-cli health
        \\  actions-data-service-cli list --limit=20 --skip=10
        \\  actions-data-service-cli get my-action-ref
        \\  actions-data-service-cli push --action=action.json
        \\  actions-data-service-cli push --reference=click-btn --name="Click Button" --description="Click submit button" --type=click --selector="#submit"
        \\  actions-data-service-cli pop my-action-ref
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
fn printVersion() void {
    std.debug.print(
        \\actions-data-service-cli version 1.0.0
        \\
    , .{});
}
