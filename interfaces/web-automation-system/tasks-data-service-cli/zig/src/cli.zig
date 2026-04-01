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

    switch (command) {
        .health => {
            const response = try engine.checkHealth(setting);

            const result = try handler.resolveCheckHealthResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_health);
        },
        .stop => {
            const response = try engine.stopService(setting);

            const result = try handler.resolveStopServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .abort => {
            const response = try engine.abortService(setting);

            const result = try handler.resolveAbortServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .start => {
            const response = try engine.startService(setting);

            const result = try handler.resolveStartServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .kill => {
            const response = try engine.killService(setting);

            const result = try handler.resolveKillServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .push => {
            const parameters = try handler.resolvePushTaskParameters(setting, command_parameters);

            const response = try engine.pushTask(setting, parameters);

            const result = try handler.resolvePushTaskResult(setting, response);

            try std.fs.File.stdout().writeAll(result.reference);
        },
        .get => {
            const parameters = try handler.resolveGetTaskParameters(command_parameters);

            const response = try engine.getTask(setting, parameters);

            const result = try handler.resolveGetTaskResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_task);
        },
        .list => {
            const parameters = try handler.resolveGetTasksParameters(command_parameters);

            const response = try engine.getTasks(setting, parameters);

            const result = try handler.resolveGetTasksResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_tasks);
        },
        .pop => {
            const parameters = try handler.resolvePopTaskParameters(command_parameters);

            const response = try engine.popTask(setting, parameters);

            const result = try handler.resolvePopTaskResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_task);
        },
    }
}
