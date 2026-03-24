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

    const command_parameters = arguments[2..];

    if (handler.checkCommandHelpFlag(command_parameters)) {
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
            const parameters = try handler.resolvePushParameters(setting, command_parameters);

            result = try engine.pushAction(setting, parameters);
        },
        .get => {
            const parameters = try handler.resolveGetParameters(command_parameters);

            const response = try engine.getAction(setting, parameters);

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
            const parameters = try handler.resolveGetActionsParameters(command_parameters);

            const response = try engine.getActions(setting, parameters);

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
            const parameters = try handler.resolvePopActionParameters(command_parameters);

            result = try engine.popAction(setting, parameters);
        },
    }

    defer setting.allocator.free(result.body);

    std.debug.print("{s}\n", .{result.body});
}
