const std = @import("std");
const handlers = @import("handlers.zig");
const engines = @import("engines.zig");
const helps = @import("helps.zig");
const routes = @import("routes.zig");

const Setting = @import("settings.zig").Setting;

pub fn run(setting: Setting, parameters: []const []const u8) !void {
    if (parameters.len < 2) {
        return helps.printUsage();
    }

    if (handlers.checkHelpFlag(parameters)) {
        return helps.printHelp();
    }

    if (handlers.checkVersionFlag(parameters)) {
        return helps.printVersion();
    }

    const command = handlers.resolveCommand(parameters[1]) catch {
        return helps.printUsage();
    };

    const command_parameters = parameters[2..];

    if (handlers.checkCommandHelpFlag(command_parameters)) {
        return helps.printCommandHelp(command);
    }

    switch (command) {
        .health => {
            const response = try engines.checkHealth(setting);

            const result = try handlers.resolveCheckHealthResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_health);
        },
        .stop => {
            const response = try engines.stopService(setting);

            const result = try handlers.resolveStopServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .abort => {
            const response = try engines.abortService(setting);

            const result = try handlers.resolveAbortServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .start => {
            const response = try engines.startService(setting);

            const result = try handlers.resolveStartServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        .kill => {
            const response = try engines.killService(setting);

            const result = try handlers.resolveKillServiceResult(setting, response);

            try std.fs.File.stdout().writeAll(result.raw_operation);
        },
        else => {
            try routes.route(command, setting, command_parameters);
        },
    }
}
