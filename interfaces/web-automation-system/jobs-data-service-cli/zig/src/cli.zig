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
            const parameters = try handler.resolvePushJobParameters(setting, command_parameters);

            const response = try engine.pushJob(setting, parameters);

            const result = try handler.resolvePushJobResult(setting, response);

            try std.fs.File.stdout().writeAll(result.reference);
        },
        .get => {
            const parameters = try handler.resolveGetJobParameters(command_parameters);

            const response = try engine.getJob(setting, parameters);

            const result = try handler.resolveGetJobResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_job);
        },
        .list => {
            const parameters = try handler.resolveGetJobsParameters(command_parameters);

            const response = try engine.getJobs(setting, parameters);

            const result = try handler.resolveGetJobsResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_jobs);
        },
        .pop => {
            const parameters = try handler.resolvePopJobParameters(command_parameters);

            const response = try engine.popJob(setting, parameters);

            const result = try handler.resolvePopJobResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_job);
        },
    }
}
