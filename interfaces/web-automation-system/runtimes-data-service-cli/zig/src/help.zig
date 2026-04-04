const std = @import("std");
const model = @import("model.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\runtimes-data-service-cli - Web automation runtimes data service CLI
        \\
        \\Usage:
        \\  runtimes-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'runtimes-data-service-cli --help' for more information.
        \\
    , .{});
}

// printHelp writes the full help message to stdout.
//
pub fn printHelp() void {
    std.debug.print(
        \\runtimes-data-service-cli - Web automation runtimes data service CLI
        \\
        \\Usage:
        \\  runtimes-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List runtimes with optional filtering
        \\  get           Get a specific runtime by reference
        \\  push          Push a new runtime to the service
        \\  pop           Remove a runtime by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N runtimes (default: 0)
        \\    --limit=N      Limit to N runtimes (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --runtime=FILE Load runtime from JSON file
        \\    OR specify inline:
        \\    --reference=           Runtime reference (required)
        \\    --session-reference=   Session reference (required)
        \\    --session-storage-state= Session storage state (required)
        \\    --queue-reference=     Queue reference (required)
        \\    --queue-name=          Queue name (required)
        \\    --queue-description=   Queue description (required)
        \\    --queue-state=         Queue state (required)
        \\    --queue-index=N        Queue index (required)
        \\    --job-reference=       Job reference (required)
        \\    --job-name=            Job name (required)
        \\    --job-description=     Job description (required)
        \\    --job-schedule=        Job schedule (required)
        \\    --task-reference=      Task reference (required)
        \\    --task-name=           Task name (required)
        \\    --task-description=    Task description (required)
        \\    --action-reference=    Action reference (required)
        \\    --action-name=         Action name (required)
        \\    --action-description=  Action description (required)
        \\    --action-type=         Action type (required)
        \\    --action-address=      Action address (optional)
        \\    --action-selector=     Action selector (optional)
        \\    --action-value=        Action value (optional)
        \\    --action-script=       Action script (optional)
        \\    --action-delay=N       Action delay in milliseconds (optional)
        \\    --state=               Runtime state (required)
        \\    --issue=               Runtime issue (optional)
        \\
        \\Examples:
        \\  runtimes-data-service-cli health
        \\  runtimes-data-service-cli list --limit=20 --skip=10
        \\  runtimes-data-service-cli get my-runtime-ref
        \\  runtimes-data-service-cli push --runtime=runtime.json
        \\  runtimes-data-service-cli pop my-runtime-ref
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\runtimes-data-service-cli version 0.0.0
        \\
    , .{});
}

// printCommandHelp prints help for specific commands
//
pub fn printCommandHelp(command: Command) void {
    switch (command) {
        .health => {
            std.debug.print(
                \\health - Check service health status
                \\
                \\Usage:
                \\  runtimes-data-service-cli health
                \\
                \\Description:
                \\  Checks if the runtimes data service is running and responsive.
                \\
            , .{});
        },
        .stop => {
            std.debug.print(
                \\stop - Stop the service
                \\
                \\Usage:
                \\  runtimes-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the runtimes data service.
                \\
            , .{});
        },
        .abort => {
            std.debug.print(
                \\abort - Abort the service
                \\
                \\Usage:
                \\  runtimes-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the runtimes data service.
                \\
            , .{});
        },
        .start => {
            std.debug.print(
                \\start - Start the service
                \\
                \\Usage:
                \\  runtimes-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the runtimes data service.
                \\
            , .{});
        },
        .kill => {
            std.debug.print(
                \\kill - Kill the service
                \\
                \\Usage:
                \\  runtimes-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the runtimes data service.
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\push - Push a new runtime to the service
                \\
                \\Usage:
                \\  runtimes-data-service-cli push --runtime=FILE
                \\  runtimes-data-service-cli push --reference= --session-reference= ... [options]
                \\
                \\Options (file mode):
                \\  --runtime=FILE Load runtime from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=           Runtime reference (required)
                \\  --session-reference=   Session reference (required)
                \\  --session-storage-state= Session storage state (required)
                \\  --queue-reference=     Queue reference (required)
                \\  --queue-name=          Queue name (required)
                \\  --queue-description=   Queue description (required)
                \\  --queue-state=         Queue state (required)
                \\  --queue-index=N        Queue index (required)
                \\  --job-reference=       Job reference (required)
                \\  --job-name=            Job name (required)
                \\  --job-description=     Job description (required)
                \\  --job-schedule=        Job schedule (required)
                \\  --task-reference=      Task reference (required)
                \\  --task-name=           Task name (required)
                \\  --task-description=    Task description (required)
                \\  --action-reference=    Action reference (required)
                \\  --action-name=         Action name (required)
                \\  --action-description=  Action description (required)
                \\  --action-type=         Action type (required)
                \\  --action-address=      Action address (optional)
                \\  --action-selector=     Action selector (optional)
                \\  --action-value=        Action value (optional)
                \\  --action-script=       Action script (optional)
                \\  --action-delay=N       Action delay in milliseconds (optional)
                \\  --state=               Runtime state (required)
                \\  --issue=               Runtime issue (optional)
                \\
                \\Examples:
                \\  runtimes-data-service-cli push --runtime=runtime.json
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\get - Get a specific runtime by reference
                \\
                \\Usage:
                \\  runtimes-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Runtime reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  runtimes-data-service-cli get my-runtime-ref
                \\  runtimes-data-service-cli get my-runtime-ref --output=./runtimes
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\list - List runtimes with optional filtering
                \\
                \\Usage:
                \\  runtimes-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N runtimes (default: 0)
                \\  --limit=N      Limit to N runtimes (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  runtimes-data-service-cli list
                \\  runtimes-data-service-cli list --limit=20
                \\  runtimes-data-service-cli list --skip=10 --limit=5 --output=./runtimes
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\pop - Remove a runtime by reference
                \\
                \\Usage:
                \\  runtimes-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Runtime reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  runtimes-data-service-cli pop my-runtime-ref
                \\
            , .{});
        },
    }
}
