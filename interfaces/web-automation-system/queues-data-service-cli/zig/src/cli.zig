const std = @import("std");
const handler = @import("handlers.zig");
const engine = @import("engines.zig");
const help = @import("helps.zig");

const Setting = @import("settings.zig").Setting;

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
            const parameters = try handler.resolvePushQueueParameters(setting, command_parameters);

            const response = try engine.pushQueue(setting, parameters);

            const result = try handler.resolvePushQueueResult(setting, response);

            try std.fs.File.stdout().writeAll(result.reference);
        },
        .get => {
            const parameters = try handler.resolveGetQueueParameters(command_parameters);

            const response = try engine.getQueue(setting, parameters);

            const result = try handler.resolveGetQueueResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_queue);
        },
        .list => {
            const parameters = try handler.resolveGetQueuesParameters(command_parameters);

            const response = try engine.getQueues(setting, parameters);

            const result = try handler.resolveGetQueuesResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_queues);
        },
        .pop => {
            const parameters = try handler.resolvePopQueueParameters(command_parameters);

            const response = try engine.popQueue(setting, parameters);

            const result = try handler.resolvePopQueueResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_queue);
        },
    }
}
