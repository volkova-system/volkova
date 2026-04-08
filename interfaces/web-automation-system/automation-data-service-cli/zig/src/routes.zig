const std = @import("std");
const handler = @import("handlers.zig");
const engine = @import("engines.zig");
const help = @import("helps.zig");

const Setting = @import("settings.zig").Setting;
const Command = @import("models.zig").Command;

const actions = @import("interfaces/actions-data-service-cli/zig/src/cli.zig");
const actions_settings = @import("interfaces/actions-data-service-cli/zig/src/settings.zig");
const tasks = @import("interfaces/tasks-data-service-cli/zig/src/cli.zig");
const tasks_settings = @import("interfaces/tasks-data-service-cli/zig/src/settings.zig");
const jobs = @import("interfaces/jobs-data-service-cli/zig/src/cli.zig");
const jobs_settings = @import("interfaces/jobs-data-service-cli/zig/src/settings.zig");
const queues = @import("interfaces/queues-data-service-cli/zig/src/cli.zig");
const queues_settings = @import("interfaces/queues-data-service-cli/zig/src/settings.zig");
const sessions = @import("interfaces/sessions-data-service-cli/zig/src/cli.zig");
const sessions_settings = @import("interfaces/sessions-data-service-cli/zig/src/settings.zig");
const runtimes = @import("interfaces/runtimes-data-service-cli/zig/src/cli.zig");
const runtimes_settings = @import("interfaces/runtimes-data-service-cli/zig/src/settings.zig");

pub fn route(command: Command, setting: Setting, parameters: []const []const u8) !void {
    switch (command) {
        .actions => {
            try actions.run(
                actions_settings.load(setting.allocator),
                parameters,
            );
        },
        .tasks => {
            try tasks.run(
                tasks_settings.load(setting.allocator),
                parameters,
            );
        },
        .jobs => {
            try jobs.run(
                jobs_settings.load(setting.allocator),
                parameters,
            );
        },
        .queues => {
            try queues.run(
                queues_settings.load(setting.allocator),
                parameters,
            );
        },
        .sessions => {
            try sessions.run(
                sessions_settings.load(setting.allocator),
                parameters,
            );
        },
        .runtimes => {
            try runtimes.run(
                runtimes_settings.load(setting.allocator),
                parameters,
            );
        },
        else => {
            return help.printUsage();
        },
    }
}
