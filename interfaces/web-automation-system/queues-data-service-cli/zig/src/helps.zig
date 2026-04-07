const std = @import("std");
const model = @import("models.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\
        \\
        \\queues-data-service-cli - Web automation queues data service CLI
        \\
        \\Usage:
        \\  queues-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'queues-data-service-cli --help' for more information.
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
        \\queues-data-service-cli - Web automation queues data service CLI
        \\
        \\Usage:
        \\  queues-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List queues with optional filtering
        \\  get           Get a specific queue by reference
        \\  push          Push a new queue to the service
        \\  pop           Remove a queue by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N queues (default: 0)
        \\    --limit=N      Limit to N queues (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --queue=FILE   Load queue from JSON file
        \\
        \\    OR specify inline:
        \\    --reference=   Queue reference (required)
        \\    --name=        Queue name (required)
        \\    --description= Queue description (optional)
        \\    --state=       Queue state (optional, default: pending)
        \\    --index=N      Queue index (optional, default: 0)
        \\
        \\    Job details (required):
        \\    --job-reference=      Job reference (required)
        \\    --job-name=           Job name (required)
        \\    --job-description=    Job description (optional)
        \\    --job-schedule=       Cron schedule expression (optional)
        \\
        \\    Optionally include a single task with a single action:
        \\    --task-reference=     Task reference (required when task provided)
        \\    --task-name=          Task name (required when task provided)
        \\    --task-description=   Task description (optional)
        \\    --action-reference=   Action reference (required when action provided)
        \\    --action-name=        Action name (required when action provided)
        \\    --action-description= Action description (optional)
        \\    --action-flow=        Action flow (required when action provided)
        \\    --action-address=     Target address (optional)
        \\    --action-selector=    Element selector (optional)
        \\    --action-value=       Input value (optional)
        \\    --action-script=      Script to execute (optional)
        \\    --action-delay=N      Delay in milliseconds (optional)
        \\
        \\Examples:
        \\  queues-data-service-cli health
        \\  queues-data-service-cli list --limit=20 --skip=10
        \\  queues-data-service-cli get my-queue-ref
        \\  queues-data-service-cli push --queue=queue.json
        \\  queues-data-service-cli push --reference=queue-1 --name="Queue" --job-reference=job-1 --job-name="Job" --task-reference=task-1 --task-name="Task" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
        \\  queues-data-service-cli pop my-queue-ref
        \\
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\queues-data-service-cli version, 0.0.0
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
                \\  queues-data-service-cli health
                \\
                \\Description:
                \\  Checks if the queues data service is running and responsive.
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
                \\  queues-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the queues data service.
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
                \\  queues-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the queues data service.
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
                \\  queues-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the queues data service.
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
                \\  queues-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the queues data service.
                \\
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\
                \\
                \\push - Push a new queue to the service
                \\
                \\Usage:
                \\  queues-data-service-cli push --queue=FILE
                \\  queues-data-service-cli push --reference= --name= --job-reference= --job-name= [options]
                \\
                \\Options (file mode):
                \\  --queue=FILE   Load queue from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=   Queue reference (required)
                \\  --name=        Queue name (required)
                \\  --description= Queue description (optional)
                \\  --state=       Queue state (optional, default: pending)
                \\  --index=N      Queue index (optional, default: 0)
                \\
                \\Job details (required):
                \\  --job-reference=      Job reference (required)
                \\  --job-name=           Job name (required)
                \\  --job-description=    Job description (optional)
                \\  --job-schedule=       Cron schedule expression (optional)
                \\
                \\Optional single task:
                \\  --task-reference=     Task reference (required when task provided)
                \\  --task-name=          Task name (required when task provided)
                \\  --task-description=   Task description (optional)
                \\
                \\Optional single action within task:
                \\  --action-reference=   Action reference (required when action provided)
                \\  --action-name=        Action name (required when action provided)
                \\  --action-description= Action description (optional)
                \\  --action-flow=        Action flow (required when action provided)
                \\  --action-address=     Target address (optional)
                \\  --action-selector=    Element selector (optional)
                \\  --action-value=       Input value (optional)
                \\  --action-script=      Script to execute (optional)
                \\  --action-delay=N      Delay in milliseconds (optional)
                \\
                \\Examples:
                \\  queues-data-service-cli push --queue=queue.json
                \\  queues-data-service-cli push --reference=queue-1 --name="Queue" --job-reference=job-1 --job-name="Job" --task-reference=task-1 --task-name="Task" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
                \\
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\
                \\
                \\get - Get a specific queue by reference
                \\
                \\Usage:
                \\  queues-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Queue reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  queues-data-service-cli get my-queue-ref
                \\  queues-data-service-cli get my-queue-ref --output=./queues
                \\
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\
                \\
                \\list - List queues with optional filtering
                \\
                \\Usage:
                \\  queues-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N queues (default: 0)
                \\  --limit=N      Limit to N queues (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  queues-data-service-cli list
                \\  queues-data-service-cli list --limit=20
                \\  queues-data-service-cli list --skip=10 --limit=5 --output=./queues
                \\
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\
                \\
                \\pop - Remove a queue by reference
                \\
                \\Usage:
                \\  queues-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Queue reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  queues-data-service-cli pop my-queue-ref
                \\
                \\
            , .{});
        },
    }
}
