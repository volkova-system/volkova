const std = @import("std");
const handler = @import("handler.zig");
const engine = @import("engine.zig");
const help = @import("help.zig");

const Setting = @import("setting.zig").Setting;

pub fn run(setting: Setting) !void {
    const arguments = try std.process.argsAlloc(setting.allocator);

    defer std.process.argsFree(setting.allocator, arguments);

    if (arguments.len < 2) {
        return help.printUsage();
    }

    if (handler.checkHelpFlag(arguments)) {
        return help.printHelp();
    }

    if (handler.checkVersionFlag(arguments)) {
        return help.printVersion();
    }

    const command = handler.resolveCommand(arguments[1]) catch {
        return help.printUsage();
    };

    const rest = arguments[2..];

    if (handler.checkCommandHelpFlag(rest)) {
        return help.printCommandHelp(command);
    }

    var result: engine.Response = undefined;
    switch (command) {
        .health => {
            result = try engine.checkHealth(setting);
        },
        .stop => {
            result = try engine.stopService(setting);
        },
        .push => {
            const parameters = try handler.resolvePushParameters(allocator, rest);

            result = try engine.pushAction(allocator, allocated_setting, parameters);
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

        .pop => {
            const reference = try handler.resolveReference(rest);

            result = try engine.popAction(allocator, allocated_setting, reference);
        },
    }

    defer allocator.free(result.body);

    std.debug.print("{s}\n", .{result.body});
}
