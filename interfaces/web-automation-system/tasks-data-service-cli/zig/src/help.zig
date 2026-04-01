const std = @import("std");
const model = @import("model.zig");

const Command = model.Command;

// printUsage writes a brief usage message to stderr.
//
pub fn printUsage() void {
    std.debug.print(
        \\tasks-data-service-cli - Web automation tasks data service CLI
        \\
        \\Usage:
        \\  tasks-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Use 'tasks-data-service-cli --help' for more information.
        \\
    , .{});
}

// printHelp writes the full help message to stdout.
//
pub fn printHelp() void {
    std.debug.print(
        \\tasks-data-service-cli - Web automation tasks data service CLI
        \\
        \\Usage:
        \\  tasks-data-service-cli [global options] <command> [command options] [arguments]
        \\
        \\Commands:
        \\  health        Check service health status
        \\  stop          Stop the service
        \\  abort         Abort the service
        \\  start         Start the service
        \\  kill          Kill the service
        \\
        \\  list          List tasks with optional filtering
        \\  get           Get a specific task by reference
        \\  push          Push a new task to the service
        \\  pop           Remove a task by reference
        \\
        \\Global Options:
        \\  -h, --help       Show this help message
        \\  -v, --version    Show version information
        \\
        \\Command Options:
        \\  list:
        \\    --skip=N       Skip N tasks (default: 0)
        \\    --limit=N      Limit to N tasks (default: 10)
        \\    --output=DIR   Save output to directory
        \\
        \\  get:
        \\    --output=DIR   Save output to directory
        \\
        \\  push:
        \\    --task=FILE    Load task from JSON file
        \\    OR specify inline:
        \\    --reference=   Task reference (required)
        \\    --name=        Task name (required)
        \\    --description= Task description (required)
        \\    Optionally include a single action:
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
        \\  tasks-data-service-cli health
        \\  tasks-data-service-cli list --limit=20 --skip=10
        \\  tasks-data-service-cli get my-task-ref
        \\  tasks-data-service-cli push --task=task.json
        \\  tasks-data-service-cli push --reference=task-1 --name="Task" --description="Demo" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
        \\  tasks-data-service-cli pop my-task-ref
        \\
    , .{});
}

// printVersion writes version information to stdout.
//
pub fn printVersion() void {
    std.debug.print(
        \\tasks-data-service-cli version 0.0.0
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
                \\  tasks-data-service-cli health
                \\
                \\Description:
                \\  Checks if the tasks data service is running and responsive.
                \\
            , .{});
        },
        .stop => {
            std.debug.print(
                \\stop - Stop the service
                \\
                \\Usage:
                \\  tasks-data-service-cli stop
                \\
                \\Description:
                \\  Sends a stop signal to the tasks data service.
                \\
            , .{});
        },
        .abort => {
            std.debug.print(
                \\abort - Abort the service
                \\
                \\Usage:
                \\  tasks-data-service-cli abort
                \\
                \\Description:
                \\  Sends an abort signal to the tasks data service.
                \\
            , .{});
        },
        .start => {
            std.debug.print(
                \\start - Start the service
                \\
                \\Usage:
                \\  tasks-data-service-cli start
                \\
                \\Description:
                \\  Sends a start signal to the tasks data service.
                \\
            , .{});
        },
        .kill => {
            std.debug.print(
                \\kill - Kill the service
                \\
                \\Usage:
                \\  tasks-data-service-cli kill
                \\
                \\Description:
                \\  Sends a kill signal to the tasks data service.
                \\
            , .{});
        },
        .push => {
            std.debug.print(
                \\push - Push a new task to the service
                \\
                \\Usage:
                \\  tasks-data-service-cli push --task=FILE
                \\  tasks-data-service-cli push --reference= --name= --description= [action options]
                \\
                \\Options (file mode):
                \\  --task=FILE    Load task from JSON file
                \\
                \\Options (inline mode):
                \\  --reference=   Task reference (required)
                \\  --name=        Task name (required)
                \\  --description= Task description (required)
                \\
                \\Optional single action:
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
                \\  tasks-data-service-cli push --task=task.json
                \\  tasks-data-service-cli push --reference=task-1 --name="Task" --description="Demo" --action-reference=act-1 --action-name="Click" --action-flow=click --action-selector="#submit"
                \\
            , .{});
        },
        .get => {
            std.debug.print(
                \\get - Get a specific task by reference
                \\
                \\Usage:
                \\  tasks-data-service-cli get <reference> [options]
                \\
                \\Arguments:
                \\  <reference>    Task reference identifier
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  tasks-data-service-cli get my-task-ref
                \\  tasks-data-service-cli get my-task-ref --output=./tasks
                \\
            , .{});
        },
        .list => {
            std.debug.print(
                \\list - List tasks with optional filtering
                \\
                \\Usage:
                \\  tasks-data-service-cli list [options]
                \\
                \\Options:
                \\  --skip=N       Skip N tasks (default: 0)
                \\  --limit=N      Limit to N tasks (default: 10)
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  tasks-data-service-cli list
                \\  tasks-data-service-cli list --limit=20
                \\  tasks-data-service-cli list --skip=10 --limit=5 --output=./tasks
                \\
            , .{});
        },
        .pop => {
            std.debug.print(
                \\pop - Remove a task by reference
                \\
                \\Usage:
                \\  tasks-data-service-cli pop <reference>
                \\
                \\Arguments:
                \\  <reference>    Task reference identifier to remove
                \\
                \\Options:
                \\  --output=DIR   Save output to directory
                \\
                \\Examples:
                \\  tasks-data-service-cli pop my-task-ref
                \\
            , .{});
        },
    }
}
