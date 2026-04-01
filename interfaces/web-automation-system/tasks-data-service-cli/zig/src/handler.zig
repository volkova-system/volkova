const std = @import("std");
const model = @import("model.zig");

const Setting = @import("setting.zig").Setting;
const Response = @import("request.zig").Response;

const Command = model.Command;
const Action = model.Action;
const Task = model.Task;

const PushTaskParameters = model.PushTaskParameters;
const GetTaskParameters = model.GetTaskParameters;
const GetTasksParameters = model.GetTasksParameters;
const PopTaskParameters = model.PopTaskParameters;

const Health = model.Health;
const Operation = model.Operation;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

const PushTaskResult = model.PushTaskResult;
const GetTaskResult = model.GetTaskResult;
const GetTasksResult = model.GetTasksResult;
const PopTaskResult = model.PopTaskResult;

pub fn checkVersionFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--version") or std.mem.eql(u8, argument_value, "-v")) {
            return true;
        }
    }
    return false;
}

pub fn checkHelpFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--help") or std.mem.eql(u8, argument_value, "-h")) {
            return true;
        }
    }
    return false;
}

pub fn checkCommandHelpFlag(arguments: []const []const u8) bool {
    for (arguments) |argument_value| {
        if (std.mem.eql(u8, argument_value, "--help") or std.mem.eql(u8, argument_value, "-h")) {
            return true;
        }
    }
    return false;
}

pub fn resolveCommand(raw: []const u8) !Command {
    if (std.mem.eql(u8, raw, "health")) return .health;
    if (std.mem.eql(u8, raw, "stop")) return .stop;
    if (std.mem.eql(u8, raw, "abort")) return .abort;
    if (std.mem.eql(u8, raw, "start")) return .start;
    if (std.mem.eql(u8, raw, "kill")) return .kill;
    if (std.mem.eql(u8, raw, "list")) return .list;
    if (std.mem.eql(u8, raw, "get")) return .get;
    if (std.mem.eql(u8, raw, "push")) return .push;
    if (std.mem.eql(u8, raw, "pop")) return .pop;
    return error.UnknownCommand;
}

pub fn resolvePushTaskParameters(setting: Setting, arguments: []const []const u8) !PushTaskParameters {
    var task_file: ?[]const u8 = null;
    var reference: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var description: ?[]const u8 = null;
    var action_reference: ?[]const u8 = null;
    var action_name: ?[]const u8 = null;
    var action_description: ?[]const u8 = null;
    var action_flow: ?[]const u8 = null;
    var action_address: ?[]const u8 = null;
    var action_selector: ?[]const u8 = null;
    var action_value: ?[]const u8 = null;
    var action_script: ?[]const u8 = null;
    var action_delay: ?u32 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--task=")) {
            task_file = argument_value["--task=".len..];
            return try resolvePushTaskParametersFromFile(setting.allocator, task_file.?);
        } else if (std.mem.startsWith(u8, argument_value, "--reference=")) {
            reference = argument_value["--reference=".len..];
            if (reference) |reference_value| if (reference_value.len == 0) return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--name=")) {
            name = argument_value["--name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--description=")) {
            description = argument_value["--description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-reference=")) {
            action_reference = argument_value["--action-reference=".len..];
            if (action_reference) |value| if (value.len == 0) return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--action-name=")) {
            action_name = argument_value["--action-name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-description=")) {
            action_description = argument_value["--action-description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--action-flow=")) {
            action_flow = argument_value["--action-flow=".len..];
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
            action_delay = std.fmt.parseInt(u32, raw, 10) catch return error.InvalidDelay;
        }
    }

    var actions: std.ArrayList(Action) = .empty;
    defer actions.deinit(setting.allocator);

    if (action_flow != null or action_reference != null or action_name != null) {
        if (action_reference == null) return error.MissingReference;
        if (action_name == null) return error.MissingName;
        if (action_flow == null) return error.MissingFlow;

        const act = Action{
            .reference = action_reference.?,
            .name = action_name.?,
            .description = action_description orelse "",
            .flow = action_flow.?,
            .address = action_address,
            .selector = action_selector,
            .value = action_value,
            .script = action_script,
            .delay = action_delay,
        };

        try actions.append(setting.allocator, act);
    }

    return PushTaskParameters{
        .reference = reference.?,
        .name = name.?,
        .description = description.?,
        .actions = try actions.toOwnedSlice(setting.allocator),
    };
}

fn resolvePushTaskParametersFromFile(allocator: std.mem.Allocator, path: []const u8) !PushTaskParameters {
    var file = std.fs.openFileAbsolute(path, .{}) catch std.fs.cwd().openFile(path, .{}) catch {
        return error.InvalidTaskFile;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, content, .{});
    defer parsed_json.deinit();

    switch (parsed_json.value) {
        .object => |object_value| {
            var reference: ?[]const u8 = null;
            var name: ?[]const u8 = null;
            var description: ?[]const u8 = null;
            var actions: std.ArrayList(Action) = .empty;
            defer actions.deinit(allocator);

            if (object_value.get("reference")) |key_value| {
                if (key_value == .string) reference = try allocator.dupe(u8, key_value.string);
                if (reference) |reference_value| if (reference_value.len == 0) return error.InvalidReference;
            }
            if (object_value.get("name")) |key_value| {
                if (key_value == .string) name = try allocator.dupe(u8, key_value.string);
            }
            if (object_value.get("description")) |key_value| {
                if (key_value == .string) description = try allocator.dupe(u8, key_value.string);
            }
            if (object_value.get("actions")) |actions_value| {
                if (actions_value == .array) {
                    for (actions_value.array.items) |action_json| {
                        if (action_json != .object) continue;
                        const obj = action_json.object;
                        var a_reference: ?[]const u8 = null;
                        var a_name: ?[]const u8 = null;
                        var a_description: ?[]const u8 = null;
                        var a_flow: ?[]const u8 = null;
                        var a_address: ?[]const u8 = null;
                        var a_selector: ?[]const u8 = null;
                        var a_value: ?[]const u8 = null;
                        var a_script: ?[]const u8 = null;
                        var a_delay: ?u32 = null;
                        if (obj.get("reference")) |kv| {
                            if (kv == .string) a_reference = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("name")) |kv| {
                            if (kv == .string) a_name = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("description")) |kv| {
                            if (kv == .string) a_description = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("flow")) |kv| {
                            if (kv == .string) a_flow = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("address")) |kv| {
                            if (kv == .string) a_address = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("selector")) |kv| {
                            if (kv == .string) a_selector = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("value")) |kv| {
                            if (kv == .string) a_value = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("script")) |kv| {
                            if (kv == .string) a_script = try allocator.dupe(u8, kv.string);
                        }
                        if (obj.get("delay")) |kv| {
                            switch (kv) {
                                .string => |sv| a_delay = std.fmt.parseInt(u32, sv, 10) catch return error.InvalidDelay,
                                .integer => |iv| a_delay = @intCast(iv),
                                else => return error.InvalidDelay,
                            }
                        }
                        if (a_reference == null) return error.MissingReference;
                        if (a_name == null) return error.MissingName;
                        if (a_flow == null) return error.MissingFlow;
                        const action = Action{
                            .reference = a_reference.?,
                            .name = a_name.?,
                            .description = a_description orelse "",
                            .flow = a_flow.?,
                            .address = a_address,
                            .selector = a_selector,
                            .value = a_value,
                            .script = a_script,
                            .delay = a_delay,
                        };
                        try actions.append(allocator, action);
                    }
                }
            }
            return PushTaskParameters{
                .reference = reference.?,
                .name = name.?,
                .description = description orelse "",
                .actions = try actions.toOwnedSlice(allocator),
            };
        },
        else => return error.InvalidTaskFile,
    }
}
pub fn resolveGetTaskParameters(arguments: []const []const u8) !GetTaskParameters {
    var reference: ?[]const u8 = null;
    var output_directory: ?[]const u8 = null;
    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];
            if (output_directory) |value| if (value.len == 0) return error.InvalidOutputDirectory;
        } else if (reference == null and !std.mem.startsWith(u8, argument_value, "--")) {
            reference = argument_value;
        }
    }
    if (reference == null or reference.?.len == 0) return error.MissingReference;
    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "task-{s}.json", .{reference.?}) catch "task.json";
    return GetTaskParameters{ .reference = reference.?, .output_directory = output_directory, .file_name = file_name };
}

pub fn resolveGetTasksParameters(arguments: []const []const u8) !GetTasksParameters {
    var skip: u32 = 0;
    var limit: u32 = 10;
    var output_directory: ?[]const u8 = null;
    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--skip=")) {
            const raw = argument_value["--skip=".len..];
            skip = std.fmt.parseInt(u32, raw, 10) catch return error.InvalidSkip;
        } else if (std.mem.startsWith(u8, argument_value, "--limit=")) {
            const raw = argument_value["--limit=".len..];
            limit = std.fmt.parseInt(u32, raw, 10) catch return error.InvalidLimit;
        } else if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];
            if (output_directory) |directory_value| if (directory_value.len == 0) return error.InvalidOutputDirectory;
        }
    }
    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "tasks-{d}-{d}.json", .{ skip, limit }) catch "tasks.json";
    return GetTasksParameters{ .skip = skip, .limit = limit, .output_directory = output_directory, .file_name = file_name };
}

pub fn resolvePopTaskParameters(arguments: []const []const u8) !PopTaskParameters {
    var reference: ?[]const u8 = null;
    var output_directory: ?[]const u8 = null;
    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];
            if (output_directory) |value| if (value.len == 0) return error.InvalidOutputDirectory;
        } else if (reference == null and !std.mem.startsWith(u8, argument_value, "--")) {
            reference = argument_value;
        }
    }
    if (reference == null or reference.?.len == 0) return error.MissingReference;
    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "task-{s}.json", .{reference.?}) catch "task.json";
    return PopTaskParameters{ .reference = reference.?, .output_directory = output_directory, .file_name = file_name };
}

pub fn resolveCheckHealthResult(setting: Setting, result: Response) !CheckHealthResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;
    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();
    if (parsed_json.value.object.get("health")) |health_value| {
        switch (health_value) {
            .object => |object_value| {
                var status: ?[]const u8 = null;
                if (object_value.get("status")) |key_value| {
                    if (key_value == .string) status = try setting.allocator.dupe(u8, key_value.string);
                }
                if (status == null) return error.MissingStatus;
                const health = Health{ .status = status.? };
                return CheckHealthResult{ .health = health, .raw_health = result.body };
            },
            else => return error.InvalidJsonFormat,
        }
    } else return error.InvalidJsonFormat;
}

pub fn resolveStopServiceResult(setting: Setting, result: Response) !StopServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);
    return StopServiceResult{ .operation = operation, .raw_operation = result.body };
}

pub fn resolveAbortServiceResult(setting: Setting, result: Response) !AbortServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);
    return AbortServiceResult{ .operation = operation, .raw_operation = result.body };
}

pub fn resolveStartServiceResult(setting: Setting, result: Response) !StartServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);
    return StartServiceResult{ .operation = operation, .raw_operation = result.body };
}

pub fn resolveKillServiceResult(setting: Setting, result: Response) !KillServiceResult {
    const operation = try resolveOperationResult(setting.allocator, result);
    return KillServiceResult{ .operation = operation, .raw_operation = result.body };
}

fn resolveOperationResult(allocator: std.mem.Allocator, result: Response) !Operation {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;
    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();
    if (parsed_json.value.object.get("operation")) |operation_value| {
        switch (operation_value) {
            .object => |object_value| {
                var status: ?[]const u8 = null;
                var procedure: ?[]const u8 = null;
                var service: ?[]const u8 = null;
                if (object_value.get("status")) |key_value| {
                    if (key_value == .string) status = try allocator.dupe(u8, key_value.string);
                }
                if (object_value.get("procedure")) |key_value| {
                    if (key_value == .string) procedure = try allocator.dupe(u8, key_value.string);
                }
                if (parsed_json.value.object.get("service")) |key_value| {
                    if (key_value == .string) service = try allocator.dupe(u8, key_value.string);
                }
                if (status == null) return error.MissingOperationStatus;
                if (procedure == null) return error.MissingOperationProcedure;
                if (service == null) return error.MissingOperationService;
                return Operation{ .status = status.?, .procedure = procedure.?, .service = service.? };
            },
            else => return error.InvalidJsonFormat,
        }
    } else return error.InvalidJsonFormat;
}

pub fn resolvePushTaskResult(setting: Setting, result: Response) !PushTaskResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;
    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();
    var reference: ?[]const u8 = null;
    if (parsed_json.value.object.get("reference")) |key_value| {
        if (key_value == .string) reference = try setting.allocator.dupe(u8, key_value.string);
    }
    if (reference == null) return error.MissingTaskReference;
    return PushTaskResult{ .reference = reference.? };
}

pub fn resolveGetTaskResult(setting: Setting, result: Response) !GetTaskResult {
    _ = setting;
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    const task = Task{
        .reference = "placeholder",
        .name = "placeholder",
        .description = "placeholder",
        .actions = &[_]Action{},
        .created_at = "",
        .updated_at = "",
    };

    return GetTaskResult{ .task = task, .raw_task = result.body };
}

pub fn resolveGetTasksResult(setting: Setting, result: Response) !GetTasksResult {
    _ = setting;
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    const tasks = &[_]Task{};

    return GetTasksResult{ .tasks = tasks, .raw_tasks = result.body };
}

pub fn resolvePopTaskResult(setting: Setting, result: Response) !PopTaskResult {
    _ = setting;
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    const task = Task{
        .reference = "placeholder",
        .name = "placeholder",
        .description = "placeholder",
        .actions = &[_]Action{},
        .created_at = "",
        .updated_at = "",
    };

    return PopTaskResult{ .task = task, .raw_task = result.body };
}
