const std = @import("std");
const handler = @import("handlers.zig");
const engine = @import("engines.zig");
const help = @import("helps.zig");

const Setting = @import("settings.zig").Setting;

pub fn run(setting: Setting, parameters: []const []const u8) !void {
    if (parameters.len < 2) {
        return help.printUsage();
    }

    if (handler.checkHelpFlag(parameters)) {
        return help.printHelp();
    }

    if (handler.checkVersionFlag(parameters)) {
        return help.printVersion();
    }

    const command = handler.resolveCommand(parameters[1]) catch {
        return help.printUsage();
    };

    const command_parameters = parameters[2..];

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
            const push_parameters = try handler.resolvePushSessionParameters(setting, command_parameters);

            const response = try engine.pushSession(setting, push_parameters);

            const result = try handler.resolvePushSessionResult(setting, response);

            try std.fs.File.stdout().writeAll(result.reference);
        },
        .get => {
            const get_parameters = try handler.resolveGetSessionParameters(command_parameters);

            const response = try engine.getSession(setting, get_parameters);

            const result = try handler.resolveGetSessionResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_session);
        },
        .list => {
            const list_parameters = try handler.resolveGetSessionsParameters(command_parameters);

            const response = try engine.getSessions(setting, list_parameters);

            const result = try handler.resolveGetSessionsResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_sessions);
        },
        .pop => {
            const pop_parameters = try handler.resolvePopSessionParameters(command_parameters);

            const response = try engine.popSession(setting, pop_parameters);

            const result = try handler.resolvePopSessionResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_session);
        },
    }
}
