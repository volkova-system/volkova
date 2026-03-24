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
            const result = try engine.checkHealth(setting);

            try std.io.getStdOut().writer().print("{s}", .{result.raw_health});
        },
        .stop => {
            const result = try engine.stopService(setting);

            try std.io.getStdOut().writer().print("{s}", .{result.raw_operation});
        },
        .push => {
            const parameters = try handler.resolvePushParameters(setting, command_parameters);

            const result = try engine.pushAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{result.reference});
        },
        .get => {
            const parameters = try handler.resolveGetParameters(command_parameters);

            const result = try engine.getAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{result.raw_action});
        },
        .list => {
            const parameters = try handler.resolveGetActionsParameters(command_parameters);

            const result = try engine.getActions(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{result.raw_actions});
        },
        .pop => {
            const parameters = try handler.resolvePopActionParameters(command_parameters);

            const result = try engine.popAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{result.raw_action});
        },
    }
}
