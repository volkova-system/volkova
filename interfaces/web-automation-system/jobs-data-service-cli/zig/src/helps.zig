const std = @import("std");
const model = @import("models.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\
        \\
        \\jobs-data-service-cli - Web automation jobs data service CLI
        \\
        \\Usage:
        \\  jobs-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'jobs-data-service-cli --help' for more information.
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
        \\jobs-data-service-cli - Web automation jobs data service CLI
        \\
        \\Usage:
        \\  jobs-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List jobs with optional filtering
        \\  get           Get a specific job by reference
        \\  push          Push a new job to the service
        \\  pop           Remove a job by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N jobs (default: 0)
        \\    --limit=N      Limit to N jobs (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --job=FILE     Load job from JSON file
        \\
        \\    OR specify inline:
        \\    --reference=   Job reference (required)
        \\    --name=        Job name (required)
        \\    --description= Job description (optional)
        \\    --schedule=    Cron schedule expression (optional)
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
        \\  jobs-data-service-cli health
        \\  jobs-data-service-cli list --limit=20 --skip=10
        \\  jobs-data-service-cli get my-job-ref
        \\  jobs-data-service-cli push --job=job.json
        \\  jobs-data-service-cli push --reference=job-1 --name="Job" --task-reference=task-1 --task-name="Task" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
        \\  jobs-data-service-cli pop my-job-ref
        \\
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\jobs-data-service-cli version 0.0.0
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
                \\  jobs-data-service-cli health
                \\
                \\Description:
                \\  Checks if the jobs data service is running and responsive.
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
                \\  jobs-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the jobs data service.
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
                \\  jobs-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the jobs data service.
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
                \\  jobs-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the jobs data service.
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
                \\  jobs-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the jobs data service.
                \\
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\push - Push a new job to the service
                \\
                \\Usage:
                \\  jobs-data-service-cli push --job=FILE
                \\  jobs-data-service-cli push --reference= --name= [--description=] [--schedule=] [task options]
                \\
                \\Options (file mode):
                \\  --job=FILE     Load job from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=   Job reference (required)
                \\  --name=        Job name (required)
                \\  --description= Job description (optional)
                \\  --schedule=    Cron schedule expression (optional)
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
                \\  jobs-data-service-cli push --job=job.json
                \\  jobs-data-service-cli push --reference=job-1 --name="Job" --task-reference=task-1 --task-name="Task" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\get - Get a specific job by reference
                \\
                \\Usage:
                \\  jobs-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Job reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  jobs-data-service-cli get my-job-ref
                \\  jobs-data-service-cli get my-job-ref --output=./jobs
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\list - List jobs with optional filtering
                \\
                \\Usage:
                \\  jobs-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N jobs (default: 0)
                \\  --limit=N      Limit to N jobs (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  jobs-data-service-cli list
                \\  jobs-data-service-cli list --limit=20
                \\  jobs-data-service-cli list --skip=10 --limit=5 --output=./jobs
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\pop - Remove a job by reference
                \\
                \\Usage:
                \\  jobs-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Job reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  jobs-data-service-cli pop my-job-ref
                \\
            , .{});
        },
    }
}
