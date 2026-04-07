const std = @import("std");
const model = @import("models.zig");

const Setting = @import("settings.zig").Setting;

const Response = @import("request.zig").Response;

const Command = model.Command;

const PushRuntimeParameters = model.PushRuntimeParameters;
const GetRuntimeParameters = model.GetRuntimeParameters;
const GetRuntimesParameters = model.GetRuntimesParameters;
const PopRuntimeParameters = model.PopRuntimeParameters;

const Health = model.Health;
const Operation = model.Operation;
const Runtime = model.Runtime;
const Session = model.Session;
const Queue = model.Queue;
const Job = model.Job;
const Task = model.Task;
const Action = model.Action;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

const PushRuntimeResult = model.PushRuntimeResult;
const GetRuntimeResult = model.GetRuntimeResult;
const GetRuntimesResult = model.GetRuntimesResult;
const PopRuntimeResult = model.PopRuntimeResult;

// checkVersionFlag checks if version is requested for a service
//
pub fn checkVersionFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--version") or
            std.mem.eql(u8, argument_value, "-v"))
        {
            return true;
        }
    }

    return false;
}

// checkHelpFlag checks if help is requested for a service
//
pub fn checkHelpFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--help") or
            std.mem.eql(u8, argument_value, "-h"))
        {
            return true;
        }
    }

    return false;
}

// checkCommandHelpFlag checks if help is requested for a command
//
pub fn checkCommandHelpFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--help") or
            std.mem.eql(u8, argument_value, "-h"))
        {
            return true;
        }
    }

    return false;
}

// resolveCommand maps a raw string argument to a Command.
// Returns error.UnknownCommand when the string is not recognized.
//
pub fn resolveCommand(raw: []const u8) !Command {
    if (std.mem.eql(u8, raw, "health"))
        return .health;

    if (std.mem.eql(u8, raw, "stop"))
        return .stop;

    if (std.mem.eql(u8, raw, "abort"))
        return .abort;

    if (std.mem.eql(u8, raw, "start"))
        return .start;

    if (std.mem.eql(u8, raw, "kill"))
        return .kill;

    if (std.mem.eql(u8, raw, "list"))
        return .list;

    if (std.mem.eql(u8, raw, "get"))
        return .get;

    if (std.mem.eql(u8, raw, "push"))
        return .push;

    if (std.mem.eql(u8, raw, "pop"))
        return .pop;

    return error.UnknownCommand;
}
// resolvePushRuntimeParameters parses required and optional push flags.
// Required: --reference= --session-reference= --session-storage-state= --queue-reference= --queue-name= --queue-description= --queue-state= --queue-index= --job-reference= --job-name= --job-description= --job-schedule= --task-reference= --task-name= --task-description= --action-reference= --action-name= --action-description= --action-type= --state=
// Optional: --action-address= --action-selector= --action-value= --action-script= --action-delay= --issue=
//
pub fn resolvePushRuntimeParameters(
    setting: Setting,
    arguments: []const []const u8,
) !PushRuntimeParameters {
    var runtime_file: ?[]const u8 = null;

    var reference: ?[]const u8 = null;

    var session_reference: ?[]const u8 = null;
    var session_storage_state: ?[]const u8 = null;

    var queue_reference: ?[]const u8 = null;
    var queue_name: ?[]const u8 = null;
    var queue_description: ?[]const u8 = null;
    var queue_state: ?[]const u8 = null;
    var queue_index: ?u32 = null;

    var job_reference: ?[]const u8 = null;
    var job_name: ?[]const u8 = null;
    var job_description: ?[]const u8 = null;
    var job_schedule: ?[]const u8 = null;

    var task_reference: ?[]const u8 = null;
    var task_name: ?[]const u8 = null;
    var task_description: ?[]const u8 = null;

    var action_reference: ?[]const u8 = null;
    var action_name: ?[]const u8 = null;
    var action_description: ?[]const u8 = null;
    var action_type: ?[]const u8 = null;

    var action_address: ?[]const u8 = null;
    var action_selector: ?[]const u8 = null;
    var action_value: ?[]const u8 = null;
    var action_script: ?[]const u8 = null;
    var action_delay: ?u32 = null;

    var state: ?[]const u8 = null;
    var issue: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--runtime=")) {
            runtime_file = argument_value["--runtime=".len..];

            return try resolvePushRuntimeParametersFromFile(setting.allocator, runtime_file.?);
        } else if (std.mem.startsWith(u8, argument_value, "--reference=")) {
            reference = argument_value["--reference=".len..];

            if (reference) |reference_value|
                if (reference_value.len == 0)
                    return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--session-reference=")) {
            session_reference = argument_value["--session-reference=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--session-storage-state=")) {
            session_storage_state = argument_value["--session-storage-state=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--queue-reference=")) {
            queue_reference = argument_value["--queue-reference=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--queue-name=")) {
            queue_name = argument_value["--queue-name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--queue-description=")) {
            queue_description = argument_value["--queue-description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--queue-state=")) {
            queue_state = argument_value["--queue-state=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--queue-index=")) {
            const raw = argument_value["--queue-index=".len..];

            queue_index = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidQueueIndex;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--job-reference=")) {
            job_reference = argument_value["--job-reference=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--job-name=")) {
            job_name = argument_value["--job-name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--job-description=")) {
            job_description = argument_value["--job-description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--job-schedule=")) {
            job_schedule = argument_value["--job-schedule=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--task-reference=")) {
            task_reference = argument_value["--task-reference=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--task-name=")) {
            task_name = argument_value["--task-name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--task-description=")) {
            task_description = argument_value["--task-description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-reference=")) {
            action_reference = argument_value["--action-reference=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-name=")) {
            action_name = argument_value["--action-name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-description=")) {
            action_description = argument_value["--action-description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-type=")) {
            action_type = argument_value["--action-type=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-address=")) {
            action_address = argument_value["--action-address=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-selector=")) {
            action_selector = argument_value["--action-selector=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-value=")) {
            action_value = argument_value["--action-value=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-script=")) {
            action_script = argument_value["--action-script=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-delay=")) {
            const raw = argument_value["--action-delay=".len..];

            action_delay = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidActionDelay;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--state=")) {
            state = argument_value["--state=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--issue=")) {
            issue = argument_value["--issue=".len..];
        }
    }

    return PushRuntimeParameters{
        .reference = reference.?,
        .session_reference = session_reference.?,
        .session_storage_state = session_storage_state.?,
        .queue_reference = queue_reference.?,
        .queue_name = queue_name.?,
        .queue_description = queue_description.?,
        .queue_state = queue_state.?,
        .queue_index = queue_index.?,
        .job_reference = job_reference.?,
        .job_name = job_name.?,
        .job_description = job_description.?,
        .job_schedule = job_schedule.?,
        .task_reference = task_reference.?,
        .task_name = task_name.?,
        .task_description = task_description.?,
        .action_reference = action_reference.?,
        .action_name = action_name.?,
        .action_description = action_description.?,
        .action_type = action_type.?,
        .action_address = action_address,
        .action_selector = action_selector,
        .action_value = action_value,
        .action_script = action_script,
        .action_delay = action_delay,
        .state = state.?,
        .issue = issue,
    };
}
fn resolvePushRuntimeParametersFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
) !PushRuntimeParameters {
    var file = std.fs.openFileAbsolute(path, .{}) catch std.fs.cwd().openFile(path, .{}) catch {
        return error.InvalidRuntimeFile;
    };

    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    defer allocator.free(content);

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, content, .{});

    defer parsed_json.deinit();

    switch (parsed_json.value) {
        .object => |object_value| {
            var reference: ?[]const u8 = null;

            var session_reference: ?[]const u8 = null;
            var session_storage_state: ?[]const u8 = null;

            var queue_reference: ?[]const u8 = null;
            var queue_name: ?[]const u8 = null;
            var queue_description: ?[]const u8 = null;
            var queue_state: ?[]const u8 = null;
            var queue_index: ?u32 = null;

            var job_reference: ?[]const u8 = null;
            var job_name: ?[]const u8 = null;
            var job_description: ?[]const u8 = null;
            var job_schedule: ?[]const u8 = null;

            var task_reference: ?[]const u8 = null;
            var task_name: ?[]const u8 = null;
            var task_description: ?[]const u8 = null;

            var action_reference: ?[]const u8 = null;
            var action_name: ?[]const u8 = null;
            var action_description: ?[]const u8 = null;
            var action_type: ?[]const u8 = null;

            var action_address: ?[]const u8 = null;
            var action_selector: ?[]const u8 = null;
            var action_value: ?[]const u8 = null;
            var action_script: ?[]const u8 = null;
            var action_delay: ?u32 = null;

            var state: ?[]const u8 = null;
            var issue: ?[]const u8 = null;

            if (object_value.get("reference")) |key_value| {
                if (key_value == .string)
                    reference = try allocator.dupe(u8, key_value.string);

                if (reference) |reference_value|
                    if (reference_value.len == 0)
                        return error.InvalidReference;
            }

            if (object_value.get("session")) |session_value| {
                if (session_value == .object) {
                    const session_object = session_value.object;

                    if (session_object.get("reference")) |key_value| {
                        if (key_value == .string)
                            session_reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (session_object.get("storage_state")) |key_value| {
                        if (key_value == .string)
                            session_storage_state = try allocator.dupe(u8, key_value.string);
                    }
                }
            }

            if (object_value.get("queue")) |queue_value| {
                if (queue_value == .object) {
                    const queue_object = queue_value.object;

                    if (queue_object.get("reference")) |key_value| {
                        if (key_value == .string)
                            queue_reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (queue_object.get("name")) |key_value| {
                        if (key_value == .string)
                            queue_name = try allocator.dupe(u8, key_value.string);
                    }

                    if (queue_object.get("description")) |key_value| {
                        if (key_value == .string)
                            queue_description = try allocator.dupe(u8, key_value.string);
                    }

                    if (queue_object.get("state")) |key_value| {
                        if (key_value == .string)
                            queue_state = try allocator.dupe(u8, key_value.string);
                    }

                    if (queue_object.get("index")) |key_value| {
                        switch (key_value) {
                            .string => |string_value| {
                                queue_index = std.fmt.parseInt(u32, string_value, 10) catch return error.InvalidQueueIndex;
                            },
                            .integer => |integer_value| {
                                queue_index = @intCast(integer_value);
                            },
                            else => {
                                return error.InvalidQueueIndex;
                            },
                        }
                    }
                }
            }

            if (object_value.get("job")) |job_value| {
                if (job_value == .object) {
                    const job_object = job_value.object;

                    if (job_object.get("reference")) |key_value| {
                        if (key_value == .string)
                            job_reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (job_object.get("name")) |key_value| {
                        if (key_value == .string)
                            job_name = try allocator.dupe(u8, key_value.string);
                    }

                    if (job_object.get("description")) |key_value| {
                        if (key_value == .string)
                            job_description = try allocator.dupe(u8, key_value.string);
                    }

                    if (job_object.get("schedule")) |key_value| {
                        if (key_value == .string)
                            job_schedule = try allocator.dupe(u8, key_value.string);
                    }
                }
            }

            if (object_value.get("task")) |task_value| {
                if (task_value == .object) {
                    const task_object = task_value.object;

                    if (task_object.get("reference")) |key_value| {
                        if (key_value == .string)
                            task_reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (task_object.get("name")) |key_value| {
                        if (key_value == .string)
                            task_name = try allocator.dupe(u8, key_value.string);
                    }

                    if (task_object.get("description")) |key_value| {
                        if (key_value == .string)
                            task_description = try allocator.dupe(u8, key_value.string);
                    }
                }
            }

            if (object_value.get("action")) |action_json| {
                if (action_json == .object) {
                    const action_object = action_json.object;

                    if (action_object.get("reference")) |key_value| {
                        if (key_value == .string)
                            action_reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("name")) |key_value| {
                        if (key_value == .string)
                            action_name = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("description")) |key_value| {
                        if (key_value == .string)
                            action_description = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("type")) |key_value| {
                        if (key_value == .string)
                            action_type = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("address")) |key_value| {
                        if (key_value == .string)
                            action_address = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("selector")) |key_value| {
                        if (key_value == .string)
                            action_selector = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("value")) |key_value| {
                        if (key_value == .string)
                            action_value = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("script")) |key_value| {
                        if (key_value == .string)
                            action_script = try allocator.dupe(u8, key_value.string);
                    }

                    if (action_object.get("delay")) |key_value| {
                        switch (key_value) {
                            .string => |string_value| {
                                action_delay = std.fmt.parseInt(u32, string_value, 10) catch return error.InvalidActionDelay;
                            },
                            .integer => |integer_value| {
                                action_delay = @intCast(integer_value);
                            },
                            else => {
                                return error.InvalidActionDelay;
                            },
                        }
                    }
                }
            }

            if (object_value.get("state")) |key_value| {
                if (key_value == .string)
                    state = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("issue")) |key_value| {
                if (key_value == .string)
                    issue = try allocator.dupe(u8, key_value.string);
            }

            return PushRuntimeParameters{
                .reference = reference.?,
                .session_reference = session_reference.?,
                .session_storage_state = session_storage_state.?,
                .queue_reference = queue_reference.?,
                .queue_name = queue_name.?,
                .queue_description = queue_description.?,
                .queue_state = queue_state.?,
                .queue_index = queue_index.?,
                .job_reference = job_reference.?,
                .job_name = job_name.?,
                .job_description = job_description.?,
                .job_schedule = job_schedule.?,
                .task_reference = task_reference.?,
                .task_name = task_name.?,
                .task_description = task_description.?,
                .action_reference = action_reference.?,
                .action_name = action_name.?,
                .action_description = action_description.?,
                .action_type = action_type.?,
                .action_address = action_address,
                .action_selector = action_selector,
                .action_value = action_value,
                .action_script = action_script,
                .action_delay = action_delay,
                .state = state.?,
                .issue = issue,
            };
        },

        else => return error.InvalidRuntimeFile,
    }
}

// resolveGetRuntimeParameters parses required reference and optional output flags.
// Required: reference
// Optional: --output=DIR
//
pub fn resolveGetRuntimeParameters(arguments: []const []const u8) !GetRuntimeParameters {
    var reference: ?[]const u8 = null;
    var output_directory: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];

            if (output_directory) |value|
                if (value.len == 0)
                    return error.InvalidOutputDirectory;
        } else if (reference == null and
            !std.mem.startsWith(u8, argument_value, "--"))
        {
            reference = argument_value;
        }
    }

    if (reference == null or reference.?.len == 0)
        return error.MissingReference;

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "runtime-{s}.json", .{reference.?}) catch "runtime.json";

    return GetRuntimeParameters{
        .reference = reference.?,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolveGetRuntimesParameters parses optional skip, limit, and output flags.
// Accepted forms: --skip=N  --limit=N  --output=DIR
// Falls back to defaults: skip=0, limit=10, output_dir=null.
//
pub fn resolveGetRuntimesParameters(arguments: []const []const u8) !GetRuntimesParameters {
    var skip: u32 = 0;
    var limit: u32 = 10;
    var output_directory: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--skip=")) {
            const raw = argument_value["--skip=".len..];

            skip = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidSkip;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--limit=")) {
            const raw = argument_value["--limit=".len..];

            limit = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidLimit;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];

            if (output_directory) |directory_value|
                if (directory_value.len == 0)
                    return error.InvalidOutputDirectory;
        }
    }

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(
        &file_name_buffer,
        "runtimes-{d}-{d}.json",
        .{ skip, limit },
    ) catch "runtimes.json";

    return GetRuntimesParameters{
        .skip = skip,
        .limit = limit,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolvePopRuntimeParameters validates that a reference argument is non-empty.
// Returns error.MissingReference when absent.
//
pub fn resolvePopRuntimeParameters(arguments: []const []const u8) !PopRuntimeParameters {
    var reference: ?[]const u8 = null;
    var output_directory: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];

            if (output_directory) |value|
                if (value.len == 0)
                    return error.InvalidOutputDirectory;
        } else if (reference == null and
            !std.mem.startsWith(u8, argument_value, "--"))
        {
            reference = argument_value;
        }
    }

    if (reference == null or reference.?.len == 0)
        return error.MissingReference;

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "runtime-{s}.json", .{reference.?}) catch "runtime.json";

    return PopRuntimeParameters{
        .reference = reference.?,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

pub fn resolveCheckHealthResult(setting: Setting, result: Response) !CheckHealthResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("health")) |health_value| {
        switch (health_value) {
            .object => |object_value| {
                var status: ?[]const u8 = null;

                if (object_value.get("status")) |key_value| {
                    if (key_value == .string)
                        status = try setting.allocator.dupe(u8, key_value.string);
                }

                if (status == null) return error.MissingStatus;

                const health = Health{
                    .status = status.?,
                };

                return CheckHealthResult{
                    .health = health,
                    .raw_health = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolveStopServiceResult(setting: Setting, result: Response) !StopServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);

    return StopServiceResult{
        .operation = operation,
        .raw_operation = result.body,
    };
}

pub fn resolveAbortServiceResult(setting: Setting, result: Response) !AbortServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);

    return AbortServiceResult{
        .operation = operation,
        .raw_operation = result.body,
    };
}

pub fn resolveStartServiceResult(setting: Setting, result: Response) !StartServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);

    return StartServiceResult{
        .operation = operation,
        .raw_operation = result.body,
    };
}

pub fn resolveKillServiceResult(setting: Setting, result: Response) !KillServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);

    return KillServiceResult{
        .operation = operation,
        .raw_operation = result.body,
    };
}

fn resolveOperationResult(allocator: std.mem.Allocator, result: Response) !Operation {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("operation")) |operation_value| {
        switch (operation_value) {
            .object => |object_value| {
                var status: ?[]const u8 = null;
                var procedure: ?[]const u8 = null;
                var service: ?[]const u8 = null;

                if (object_value.get("status")) |key_value| {
                    if (key_value == .string)
                        status = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("procedure")) |key_value| {
                    if (key_value == .string)
                        procedure = try allocator.dupe(u8, key_value.string);
                }

                if (parsed_json.value.object.get("service")) |key_value| {
                    if (key_value == .string)
                        service = try allocator.dupe(u8, key_value.string);
                }

                if (status == null) return error.MissingOperationStatus;
                if (procedure == null) return error.MissingOperationProcedure;
                if (service == null) return error.MissingOperationService;

                return Operation{
                    .status = status.?,
                    .procedure = procedure.?,
                    .service = service.?,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolvePushRuntimeResult(setting: Setting, result: Response) !PushRuntimeResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    var reference: ?[]const u8 = null;

    if (parsed_json.value.object.get("reference")) |key_value| {
        if (key_value == .string)
            reference = try setting.allocator.dupe(u8, key_value.string);
    }

    if (reference == null) return error.MissingRuntimeReference;

    return PushRuntimeResult{
        .reference = reference.?,
    };
}
pub fn resolveGetRuntimeResult(setting: Setting, result: Response) !GetRuntimeResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("runtime")) |runtime_value| {
        switch (runtime_value) {
            .object => |object_value| {
                const runtime = try resolveRuntimeFromObject(setting.allocator, object_value);

                return GetRuntimeResult{
                    .runtime = runtime,
                    .raw_runtime = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolveGetRuntimesResult(setting: Setting, result: Response) !GetRuntimesResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("runtimes")) |runtimes_value| {
        switch (runtimes_value) {
            .array => |array_value| {
                var runtimes: std.ArrayList(Runtime) = .empty;
                defer runtimes.deinit(setting.allocator);

                for (array_value.items) |runtime_json| {
                    if (runtime_json != .object) continue;

                    const runtime = try resolveRuntimeFromObject(setting.allocator, runtime_json.object);
                    try runtimes.append(setting.allocator, runtime);
                }

                return GetRuntimesResult{
                    .runtimes = try runtimes.toOwnedSlice(setting.allocator),
                    .raw_runtimes = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolvePopRuntimeResult(setting: Setting, result: Response) !PopRuntimeResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("runtime")) |runtime_value| {
        switch (runtime_value) {
            .object => |object_value| {
                const runtime = try resolveRuntimeFromObject(setting.allocator, object_value);

                return PopRuntimeResult{
                    .runtime = runtime,
                    .raw_runtime = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}
fn resolveRuntimeFromObject(allocator: std.mem.Allocator, object_value: std.json.ObjectMap) !Runtime {
    var reference: ?[]const u8 = null;

    var session_reference: ?[]const u8 = null;
    var session_storage_state: ?[]const u8 = null;

    var queue_reference: ?[]const u8 = null;
    var queue_name: ?[]const u8 = null;
    var queue_description: ?[]const u8 = null;
    var queue_state: ?[]const u8 = null;
    var queue_index: ?u32 = null;

    var job_reference: ?[]const u8 = null;
    var job_name: ?[]const u8 = null;
    var job_description: ?[]const u8 = null;
    var job_schedule: ?[]const u8 = null;

    var task_reference: ?[]const u8 = null;
    var task_name: ?[]const u8 = null;
    var task_description: ?[]const u8 = null;

    var action_reference: ?[]const u8 = null;
    var action_name: ?[]const u8 = null;
    var action_description: ?[]const u8 = null;
    var action_type: ?[]const u8 = null;

    var action_address: ?[]const u8 = null;
    var action_selector: ?[]const u8 = null;
    var action_value: ?[]const u8 = null;
    var action_script: ?[]const u8 = null;
    var action_delay: ?u32 = null;

    var state_date_time: ?[]const u8 = null;
    var state: ?[]const u8 = null;
    var issue: ?[]const u8 = null;

    var created_at: ?[]const u8 = null;
    var updated_at: ?[]const u8 = null;

    if (object_value.get("reference")) |key_value| {
        if (key_value == .string)
            reference = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("session")) |session_value| {
        if (session_value == .object) {
            const session_object = session_value.object;

            if (session_object.get("reference")) |key_value| {
                if (key_value == .string)
                    session_reference = try allocator.dupe(u8, key_value.string);
            }

            if (session_object.get("storage_state")) |key_value| {
                if (key_value == .string)
                    session_storage_state = try allocator.dupe(u8, key_value.string);
            }
        }
    }

    if (object_value.get("queue")) |queue_value| {
        if (queue_value == .object) {
            const queue_object = queue_value.object;

            if (queue_object.get("reference")) |key_value| {
                if (key_value == .string)
                    queue_reference = try allocator.dupe(u8, key_value.string);
            }

            if (queue_object.get("name")) |key_value| {
                if (key_value == .string)
                    queue_name = try allocator.dupe(u8, key_value.string);
            }

            if (queue_object.get("description")) |key_value| {
                if (key_value == .string)
                    queue_description = try allocator.dupe(u8, key_value.string);
            }

            if (queue_object.get("state")) |key_value| {
                if (key_value == .string)
                    queue_state = try allocator.dupe(u8, key_value.string);
            }

            if (queue_object.get("index")) |key_value| {
                switch (key_value) {
                    .string => |string_value| {
                        queue_index = try std.fmt.parseInt(u32, string_value, 10);
                    },
                    .integer => |integer_value| {
                        queue_index = @intCast(integer_value);
                    },
                    else => {
                        return error.InvalidQueueIndex;
                    },
                }
            }
        }
    }

    if (object_value.get("job")) |job_value| {
        if (job_value == .object) {
            const job_object = job_value.object;

            if (job_object.get("reference")) |key_value| {
                if (key_value == .string)
                    job_reference = try allocator.dupe(u8, key_value.string);
            }

            if (job_object.get("name")) |key_value| {
                if (key_value == .string)
                    job_name = try allocator.dupe(u8, key_value.string);
            }

            if (job_object.get("description")) |key_value| {
                if (key_value == .string)
                    job_description = try allocator.dupe(u8, key_value.string);
            }

            if (job_object.get("schedule")) |key_value| {
                if (key_value == .string)
                    job_schedule = try allocator.dupe(u8, key_value.string);
            }
        }
    }

    if (object_value.get("task")) |task_value| {
        if (task_value == .object) {
            const task_object = task_value.object;

            if (task_object.get("reference")) |key_value| {
                if (key_value == .string)
                    task_reference = try allocator.dupe(u8, key_value.string);
            }

            if (task_object.get("name")) |key_value| {
                if (key_value == .string)
                    task_name = try allocator.dupe(u8, key_value.string);
            }

            if (task_object.get("description")) |key_value| {
                if (key_value == .string)
                    task_description = try allocator.dupe(u8, key_value.string);
            }
        }
    }

    if (object_value.get("action")) |action_json| {
        if (action_json == .object) {
            const action_object = action_json.object;

            if (action_object.get("reference")) |key_value| {
                if (key_value == .string)
                    action_reference = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("name")) |key_value| {
                if (key_value == .string)
                    action_name = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("description")) |key_value| {
                if (key_value == .string)
                    action_description = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("type")) |key_value| {
                if (key_value == .string)
                    action_type = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("address")) |key_value| {
                if (key_value == .string)
                    action_address = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("selector")) |key_value| {
                if (key_value == .string)
                    action_selector = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("value")) |key_value| {
                if (key_value == .string)
                    action_value = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("script")) |key_value| {
                if (key_value == .string)
                    action_script = try allocator.dupe(u8, key_value.string);
            }

            if (action_object.get("delay")) |key_value| {
                switch (key_value) {
                    .string => |string_value| {
                        action_delay = try std.fmt.parseInt(u32, string_value, 10);
                    },
                    .integer => |integer_value| {
                        action_delay = @intCast(integer_value);
                    },
                    else => {
                        return error.InvalidActionDelay;
                    },
                }
            }
        }
    }

    if (object_value.get("state_date_time")) |key_value| {
        if (key_value == .string)
            state_date_time = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("state")) |key_value| {
        if (key_value == .string)
            state = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("issue")) |key_value| {
        if (key_value == .string)
            issue = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("created_at")) |key_value| {
        if (key_value == .string)
            created_at = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("updated_at")) |key_value| {
        if (key_value == .string)
            updated_at = try allocator.dupe(u8, key_value.string);
    }

    // Validate required fields
    if (reference == null) return error.MissingReference;
    if (session_reference == null) return error.MissingSessionReference;
    if (session_storage_state == null) return error.MissingSessionStorageState;
    if (queue_reference == null) return error.MissingQueueReference;
    if (queue_name == null) return error.MissingQueueName;
    if (queue_description == null) return error.MissingQueueDescription;
    if (queue_state == null) return error.MissingQueueState;
    if (queue_index == null) return error.MissingQueueIndex;
    if (job_reference == null) return error.MissingJobReference;
    if (job_name == null) return error.MissingJobName;
    if (job_description == null) return error.MissingJobDescription;
    if (job_schedule == null) return error.MissingJobSchedule;
    if (task_reference == null) return error.MissingTaskReference;
    if (task_name == null) return error.MissingTaskName;
    if (task_description == null) return error.MissingTaskDescription;
    if (action_reference == null) return error.MissingActionReference;
    if (action_name == null) return error.MissingActionName;
    if (action_description == null) return error.MissingActionDescription;
    if (action_type == null) return error.MissingActionType;
    if (state_date_time == null) return error.MissingStateDateTime;
    if (state == null) return error.MissingState;
    if (created_at == null) return error.MissingCreatedAt;
    if (updated_at == null) return error.MissingUpdatedAt;

    const session = Session{
        .reference = session_reference.?,
        .storage_state = session_storage_state.?,
    };

    const queue = Queue{
        .reference = queue_reference.?,
        .name = queue_name.?,
        .description = queue_description.?,
        .state = queue_state.?,
        .index = queue_index.?,
    };

    const job = Job{
        .reference = job_reference.?,
        .name = job_name.?,
        .description = job_description.?,
        .schedule = job_schedule.?,
    };

    const task = Task{
        .reference = task_reference.?,
        .name = task_name.?,
        .description = task_description.?,
    };

    const action = Action{
        .reference = action_reference.?,
        .name = action_name.?,
        .description = action_description.?,
        .type = action_type.?,
        .address = action_address,
        .selector = action_selector,
        .value = action_value,
        .script = action_script,
        .delay = action_delay,
    };

    return Runtime{
        .reference = reference.?,
        .session = session,
        .queue = queue,
        .job = job,
        .task = task,
        .action = action,
        .state_date_time = state_date_time.?,
        .state = state.?,
        .issue = issue,
        .created_at = created_at.?,
        .updated_at = updated_at.?,
    };
}
