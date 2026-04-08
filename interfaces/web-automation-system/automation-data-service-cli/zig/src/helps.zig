const std = @import("std");
const model = @import("models.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\
        \\
        \\automation-data-service-cli - Web automation data service CLI
        \\
        \\Usage:
        \\  automation-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'automation-data-service-cli --help' for more information.
        \\
        \\
    , .{});
}

// printHelp writes the full help message to stdout.
//
pub fn printHelp() void {
    std.debug.print(
        \\
        \\
        \\automation-data-service-cli - Web automation data service CLI
        \\
        \\Usage:
        \\  automation-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Examples:
        \\  automation-data-service-cli health
        \\
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\automation-data-service-cli version 0.0.0
    , .{});
}

// printCommandHelp prints help for specific commands
//
pub fn printCommandHelp(command: Command) void {
    switch (command) {
        .health => {
            std.debug.print(
                \\
                \\
                \\health - Check service health status
                \\
                \\Usage:
                \\  automation-data-service-cli health
                \\
                \\Description:
                \\  Checks if the automation data service is running and responsive.
                \\
                \\
            , .{});
        },
        .stop => {
            std.debug.print(
                \\
                \\
                \\stop - Stop the service
                \\
                \\Usage:
                \\  automation-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the automation data service.
                \\
                \\
            , .{});
        },
        .abort => {
            std.debug.print(
                \\
                \\
                \\abort - Abort the service
                \\
                \\Usage:
                \\  automation-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the automation data service.
                \\
                \\
            , .{});
        },
        .start => {
            std.debug.print(
                \\
                \\
                \\start - Start the service
                \\
                \\Usage:
                \\  automation-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the automation data service.
                \\
                \\
            , .{});
        },
        .kill => {
            std.debug.print(
                \\
                \\
                \\kill - Kill the service
                \\
                \\Usage:
                \\  automation-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the automation data service.
                \\
                \\
            , .{});
        },
        else => {
            std.debug.print(
                \\
                \\
                \\module - Module command group help
                \\
                \\Usage:
                \\  automation-data-service-cli <module> --help
                \\
                \\Description:
                \\  Use this to see commands for modules like actions, tasks, jobs, queues, sessions, runtimes.
                \\
                \\
            , .{});
        },
    }
}
