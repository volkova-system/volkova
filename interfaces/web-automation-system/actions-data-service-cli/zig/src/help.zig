const std = @import("std");
const model = @import("model.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\actions-data-service-cli - Web automation actions data service CLI
        \\
        \\Usage:
        \\  actions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'actions-data-service-cli --help' for more information.
        \\
    , .{});
}

// printHelp writes the full help message to stdout.
//
pub fn printHelp() void {
    std.debug.print(
        \\actions-data-service-cli - Web automation actions data service CLI
        \\
        \\Usage:
        \\  actions-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List actions with optional filtering
        \\  get           Get a specific action by reference
        \\  push          Push a new action to the service
        \\  pop           Remove an action by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N actions (default: 0)
        \\    --limit=N      Limit to N actions (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --action=FILE  Load action from JSON file
        \\    OR specify inline:
        \\    --reference=   Action reference (required)
        \\    --name=        Action name (required)
        \\    --description= Action description (required)
        \\    --flow=        Action flow (required)
        \\    --address=     Target address (optional)
        \\    --selector=    Element selector (optional)
        \\    --value=       Input value (optional)
        \\    --script=      Script to execute (optional)
        \\    --delay=N      Delay in milliseconds (optional)
        \\
        \\Examples:
        \\  actions-data-service-cli health
        \\  actions-data-service-cli list --limit=20 --skip=10
        \\  actions-data-service-cli get my-action-ref
        \\  actions-data-service-cli push --action=action.json
        \\  actions-data-service-cli push --reference=click-btn --name="Click Button" --description="Click submit button" --flow=click --selector="#submit"
        \\  actions-data-service-cli pop my-action-ref
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\actions-data-service-cli version 0.0.0
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
                \\  actions-data-service-cli health
                \\
                \\Description:
                \\  Checks if the actions data service is running and responsive.
                \\
            , .{});
        },
        .stop => {
            std.debug.print(
                \\stop - Stop the service
                \\
                \\Usage:
                \\  actions-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the actions data service.
                \\
            , .{});
        },
        .abort => {
            std.debug.print(
                \\abort - Abort the service
                \\
                \\Usage:
                \\  actions-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the actions data service.
                \\
            , .{});
        },
        .start => {
            std.debug.print(
                \\start - Start the service
                \\
                \\Usage:
                \\  actions-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the actions data service.
                \\
            , .{});
        },
        .kill => {
            std.debug.print(
                \\kill - Kill the service
                \\
                \\Usage:
                \\  actions-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the actions data service.
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\push - Push a new action to the service
                \\
                \\Usage:
                \\  actions-data-service-cli push --action=FILE
                \\  actions-data-service-cli push --reference= --name= --description= --flow= [options]
                \\
                \\Options (file mode):
                \\  --action=FILE  Load action from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=   Action reference (required)
                \\  --name=        Action name (required)
                \\  --description= Action description (required)
                \\  --flow=        Action flow (required)
                \\  --address=     Target address (optional)
                \\  --selector=    Element selector (optional)
                \\  --value=       Input value (optional)
                \\  --script=      Script to execute (optional)
                \\  --delay=N      Delay in milliseconds (optional)
                \\
                \\Examples:
                \\  actions-data-service-cli push --action=action.json
                \\  actions-data-service-cli push --reference=click-btn --name="Click Button" --description="Click submit button" --flow=click --selector="#submit"
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\get - Get a specific action by reference
                \\
                \\Usage:
                \\  actions-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Action reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  actions-data-service-cli get my-action-ref
                \\  actions-data-service-cli get my-action-ref --output=./actions
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\list - List actions with optional filtering
                \\
                \\Usage:
                \\  actions-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N actions (default: 0)
                \\  --limit=N      Limit to N actions (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  actions-data-service-cli list
                \\  actions-data-service-cli list --limit=20
                \\  actions-data-service-cli list --skip=10 --limit=5 --output=./actions
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\pop - Remove an action by reference
                \\
                \\Usage:
                \\  actions-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Action reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  actions-data-service-cli pop my-action-ref
                \\
            , .{});
        },
    }
}
