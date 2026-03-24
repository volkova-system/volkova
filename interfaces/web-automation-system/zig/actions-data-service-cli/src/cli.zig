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
            const health = try engine.checkHealth(setting);

            try std.io.getStdOut().writer().print("{s}", .{health});
        },
        .stop => {
            const operation = try engine.stopService(setting);

            try std.io.getStdOut().writer().print("{s}", .{operation});
        },
        .push => {
            const parameters = try handler.resolvePushParameters(setting, command_parameters);

            const reference = try engine.pushAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{reference});
        },
        .get => {
            const parameters = try handler.resolveGetParameters(command_parameters);

            const action = try engine.getAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{action});
        },
        .list => {
            const parameters = try handler.resolveGetActionsParameters(command_parameters);

            const actions = try engine.getActions(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{actions});
        },
        .pop => {
            const parameters = try handler.resolvePopActionParameters(command_parameters);

            const action = try engine.popAction(setting, parameters);

            try std.io.getStdOut().writer().print("{s}", .{action});
        },
    }
}
