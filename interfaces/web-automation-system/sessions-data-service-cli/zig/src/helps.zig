const std = @import("std");
const model = @import("models.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\
        \\
        \\sessions-data-service-cli - Web automation sessions data service CLI
        \\
        \\Usage:
        \\  sessions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'sessions-data-service-cli --help' for more information.
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
        \\sessions-data-service-cli - Web automation sessions data service CLI
        \\
        \\Usage:
        \\  sessions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List sessions with optional filtering
        \\  get           Get a specific session by reference
        \\  push          Push a new session to the service
        \\  pop           Remove a session by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N sessions (default: 0)
        \\    --limit=N      Limit to N sessions (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --session=FILE Load session from JSON file
        \\
        \\    OR specify inline:
        \\    --reference=   Session reference (required)
        \\    --storage-state= Storage state JSON (required)
        \\
        \\Examples:
        \\  sessions-data-service-cli health
        \\  sessions-data-service-cli list --limit=20 --skip=10
        \\  sessions-data-service-cli get my-session-ref
        \\  sessions-data-service-cli push --session=session.json
        \\  sessions-data-service-cli push --reference=sess-1 --storage-state='{"cookies":[],"localStorage":{}}'
        \\  sessions-data-service-cli pop my-session-ref
        \\
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\sessions-data-service-cli version, 0.0.0
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
                \\  sessions-data-service-cli health
                \\
                \\Description:
                \\  Checks if the sessions data service is running and responsive.
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
                \\  sessions-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the sessions data service.
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
                \\  sessions-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the sessions data service.
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
                \\  sessions-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the sessions data service.
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
                \\  sessions-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the sessions data service.
                \\
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\
                \\
                \\push - Push a new session to the service
                \\
                \\Usage:
                \\  sessions-data-service-cli push --session=FILE
                \\  sessions-data-service-cli push --reference= --storage-state=
                \\
                \\Options (file mode):
                \\  --session=FILE Load session from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=   Session reference (required)
                \\  --storage-state= Storage state JSON (required)
                \\
                \\Examples:
                \\  sessions-data-service-cli push --session=session.json
                \\  sessions-data-service-cli push --reference=sess-1 --storage-state='{"cookies":[],"localStorage":{}}'
                \\
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\
                \\
                \\get - Get a specific session by reference
                \\
                \\Usage:
                \\  sessions-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Session reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  sessions-data-service-cli get my-session-ref
                \\  sessions-data-service-cli get my-session-ref --output=./sessions
                \\
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\
                \\
                \\list - List sessions with optional filtering
                \\
                \\Usage:
                \\  sessions-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N sessions (default: 0)
                \\  --limit=N      Limit to N sessions (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  sessions-data-service-cli list
                \\  sessions-data-service-cli list --limit=20
                \\  sessions-data-service-cli list --skip=10 --limit=5 --output=./sessions
                \\
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\
                \\
                \\pop - Remove a session by reference
                \\
                \\Usage:
                \\  sessions-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Session reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  sessions-data-service-cli pop my-session-ref
                \\
                \\
            , .{});
        },
    }
}
