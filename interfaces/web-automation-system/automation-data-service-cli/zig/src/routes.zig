const std = @import("std");
const handler = @import("handlers.zig");
const engine = @import("engines.zig");
const help = @import("helps.zig");

const Setting = @import("settings.zig").Setting;
const Command = @import("models.zig").Command;

const actions = @import("interfaces/actions-data-service-cli/zig/src/cli.zig");
const tasks = @import("interfaces/tasks-data-service-cli/zig/src/cli.zig");
const jobs = @import("interfaces/jobs-data-service-cli/zig/src/cli.zig");
const queues = @import("interfaces/queues-data-service-cli/zig/src/cli.zig");
const sessions = @import("interfaces/sessions-data-service-cli/zig/src/cli.zig");
const runtimes = @import("interfaces/runtimes-data-service-cli/zig/src/cli.zig");

pub fn route(command: Command, setting: Setting, parameters: []const []const u8) !void {
    switch (command) {
        .actions => {
            try actions.run(
                setting,
                parameters,
            );
        },
        .tasks => {
            try tasks.run(
                setting,
                parameters,
            );
        },
        .jobs => {
            try jobs.run(
                setting,
                parameters,
            );
        },
        .queues => {
            try queues.run(
                setting,
                parameters,
            );
        },
        .sessions => {
            try sessions.run(
                setting,
                parameters,
            );
        },
        .runtimes => {
            try runtimes.run(
                setting,
                parameters,
            );
        },
        else => {
            return help.printUsage();
        },
    }
}
