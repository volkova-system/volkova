const std = @import("std");
const model = @import("model.zig");

const Setting = @import("setting.zig").Setting;

const Response = @import("request.zig").Response;

const Command = model.Command;

const PushActionParameters = model.PushActionParameters;
const GetActionParameters = model.GetActionParameters;
const GetActionsParameters = model.GetActionsParameters;
const PopActionParameters = model.PopActionParameters;

const Health = model.Health;
const Operation = model.Operation;
const Action = model.Action;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const PushActionResult = model.PushActionResult;
const GetActionResult = model.GetActionResult;
const GetActionsResult = model.GetActionsResult;
const PopActionResult = model.PopActionResult;

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

// resolvePushActionParameters parses required and optional push flags.
// Required: --reference=  --name=  --description=  --type=
// Optional: --address=  --selector=  --value=  --script=  --delay=
//
pub fn resolvePushActionParameters(
    setting: Setting,
    arguments: []const []const u8,
) !PushActionParameters {
    var action_file: ?[]const u8 = null;

    var reference: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var description: ?[]const u8 = null;

    var action_type: ?[]const u8 = null;

    var address: ?[]const u8 = null;
    var selector: ?[]const u8 = null;
    var value: ?[]const u8 = null;
    var script: ?[]const u8 = null;

    var delay: ?u32 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--action=")) {
            action_file = argument_value["--action=".len..];

            return try resolvePushActionParametersFromFile(setting.allocator, action_file.?);
        } else if (std.mem.startsWith(u8, argument_value, "--reference=")) {
            reference = argument_value["--reference=".len..];

            if (reference) |reference_value|
                if (reference_value.len == 0)
                    return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--name=")) {
            name = argument_value["--name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--description=")) {
            description = argument_value["--description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--type=")) {
            action_type = argument_value["--type=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--address=")) {
            address = argument_value["--address=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--selector=")) {
            selector = argument_value["--selector=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--value=")) {
            value = argument_value["--value=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--script=")) {
            script = argument_value["--script=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--delay=")) {
            const raw = argument_value["--delay=".len..];

            delay = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidDelay;
            };
        }
    }

    return PushActionParameters{
        .reference = reference.?,
        .name = name.?,
        .description = description.?,

        .action_type = action_type.?,

        .address = address,
        .selector = selector,
        .value = value,
        .script = script,

        .delay = delay,
    };
}

fn resolvePushActionParametersFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
) !PushActionParameters {
    var file = std.fs.openFileAbsolute(path, .{}) catch std.fs.cwd().openFile(path, .{}) catch {
        return error.InvalidActionFile;
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
            var action_type: ?[]const u8 = null;

            var address: ?[]const u8 = null;
            var selector: ?[]const u8 = null;
            var value: ?[]const u8 = null;
            var script: ?[]const u8 = null;

            var delay: ?u32 = null;

            if (object_value.get("reference")) |key_value| {
                if (key_value == .string)
                    reference = try allocator.dupe(u8, key_value.string);

                if (reference) |reference_value|
                    if (reference_value.len == 0)
                        return error.InvalidReference;
            }

            if (object_value.get("name")) |key_value| {
                if (key_value == .string)
                    name = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("description")) |key_value| {
                if (key_value == .string)
                    description = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("type")) |key_value| {
                if (key_value == .string)
                    action_type = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("address")) |key_value| {
                if (key_value == .string)
                    address = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("selector")) |key_value| {
                if (key_value == .string)
                    selector = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("value")) |key_value| {
                if (key_value == .string)
                    value = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("script")) |key_value| {
                if (key_value == .string)
                    script = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("delay")) |key_value| {
                if (key_value == .string) {
                    delay = std.fmt.parseInt(u32, key_value.string, 10) catch return error.InvalidDelay;
                }
            }

            return PushActionParameters{
                .reference = reference.?,
                .name = name.?,
                .description = description.?,

                .action_type = action_type.?,

                .address = address,
                .selector = selector,
                .value = value,
                .script = script,

                .delay = delay,
            };
        },

        else => return error.InvalidActionFile,
    }
}

// resolveGetActionParameters parses required reference and optional output flags.
// Required: reference
// Optional: --output=DIR
//
pub fn resolveGetActionParameters(arguments: []const []const u8) !GetActionParameters {
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
    const file_name = std.fmt.bufPrint(&file_name_buffer, "action-{s}.json", .{reference.?}) catch "action.json";

    return GetActionParameters{
        .reference = reference.?,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolveGetActionsParameters parses optional skip, limit, and output flags.
// Accepted forms: --skip=N  --limit=N  --output=DIR
// Falls back to defaults: skip=0, limit=10, output_dir=null.
//
pub fn resolveGetActionsParameters(arguments: []const []const u8) !GetActionsParameters {
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
        "actions-{d}-{d}.json",
        .{ skip, limit },
    ) catch "actions.json";

    return GetActionsParameters{
        .skip = skip,
        .limit = limit,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolvePopActionParameters validates that a reference argument is non-empty.
// Returns error.MissingReference when absent.
//
pub fn resolvePopActionParameters(arguments: []const []const u8) !PopActionParameters {
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
    const file_name = std.fmt.bufPrint(&file_name_buffer, "action-{s}.json", .{reference.?}) catch "action.json";

    return PopActionParameters{
        .reference = reference.?,

        .output_directory = output_directory,
        .file_name = file_name,
    };
}

pub fn resolveCheckHealthResult(allocator: std.mem.Allocator, result: Response) !CheckHealthResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("health")) |health_value| {
        switch (health_value) {
            .object => |object_value| {
                var status: ?[]const u8 = null;
                var service: ?[]const u8 = null;
                var issue: ?[]const u8 = null;

                if (object_value.get("status")) |key_value| {
                    if (key_value == .string)
                        status = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("service")) |key_value| {
                    if (key_value == .string)
                        service = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("issue")) |key_value| {
                    if (key_value == .string)
                        issue = try allocator.dupe(u8, key_value.string);
                }

                if (status == null) return error.MissingStatus;
                if (service == null) return error.MissingService;

                const health = Health{
                    .status = status.?,
                    .service = service.?,
                    .issue = issue,
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

pub fn resolveStopServiceResult(allocator: std.mem.Allocator, result: Response) !StopServiceResult {
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
                var operation_type: ?[]const u8 = null;
                var service: ?[]const u8 = null;

                if (object_value.get("status")) |key_value| {
                    if (key_value == .string)
                        status = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("type")) |key_value| {
                    if (key_value == .string)
                        operation_type = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("service")) |key_value| {
                    if (key_value == .string)
                        service = try allocator.dupe(u8, key_value.string);
                }

                if (status == null) return error.MissingOperationStatus;
                if (operation_type == null) return error.MissingOperationType;
                if (service == null) return error.MissingOperationService;

                const operation = Operation{
                    .status = status.?,
                    .type = operation_type.?,
                    .service = service.?,
                };

                return StopServiceResult{
                    .operation = operation,
                    .raw_operation = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolvePushActionResult(allocator: std.mem.Allocator, result: Response) !PushActionResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    var reference: ?[]const u8 = null;

    if (parsed_json.value.object.get("reference")) |key_value| {
        if (key_value == .string)
            reference = try allocator.dupe(u8, key_value.string);
    }

    if (reference == null) return error.MissingActionReference;

    return PushActionResult{
        .reference = reference.?,
    };
}

pub fn resolveGetActionResult(allocator: std.mem.Allocator, result: Response) !GetActionResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("action")) |action_value| {
        switch (action_value) {
            .object => |object_value| {
                var reference: ?[]const u8 = null;
                var name: ?[]const u8 = null;
                var description: ?[]const u8 = null;
                var action_type: ?[]const u8 = null;

                var address: ?[]const u8 = null;
                var selector: ?[]const u8 = null;
                var value: ?[]const u8 = null;
                var script: ?[]const u8 = null;

                var delay: ?u32 = null;

                if (object_value.get("reference")) |key_value| {
                    if (key_value == .string)
                        reference = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("name")) |key_value| {
                    if (key_value == .string)
                        name = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("description")) |key_value| {
                    if (key_value == .string)
                        description = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("type")) |key_value| {
                    if (key_value == .string)
                        action_type = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("address")) |key_value| {
                    if (key_value == .string)
                        address = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("selector")) |key_value| {
                    if (key_value == .string)
                        selector = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("value")) |key_value| {
                    if (key_value == .string)
                        value = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("script")) |key_value| {
                    if (key_value == .string)
                        script = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("delay")) |key_value| {
                    if (key_value == .number) {
                        delay = @intFromFloat(key_value.number);
                    } else if (key_value == .string) {
                        delay = std.fmt.parseInt(u32, key_value.string, 10) catch null;
                    }
                }

                // Validate required fields
                if (reference == null) return error.MissingReference;
                if (name == null) return error.MissingName;
                if (description == null) return error.MissingDescription;
                if (action_type == null) return error.MissingActionType;

                const action = Action{
                    .reference = reference.?,
                    .name = name.?,
                    .description = description.?,
                    .action_type = action_type.?,
                    .address = address,
                    .selector = selector,
                    .value = value,
                    .script = script,
                    .delay = delay,
                };

                return GetActionResult{
                    .action = action,
                    .raw_action = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolveGetActionsResult(allocator: std.mem.Allocator, result: Response) !GetActionsResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("actions")) |actions_value| {
        switch (actions_value) {
            .array => |array_value| {
                var actions = std.ArrayList(Action).init(allocator);
                defer actions.deinit();

                for (array_value.items) |action_json| {
                    if (action_json != .object) continue;

                    const object_value = action_json.object;

                    var reference: ?[]const u8 = null;
                    var name: ?[]const u8 = null;
                    var description: ?[]const u8 = null;
                    var action_type: ?[]const u8 = null;

                    var address: ?[]const u8 = null;
                    var selector: ?[]const u8 = null;
                    var value: ?[]const u8 = null;
                    var script: ?[]const u8 = null;

                    var delay: ?u32 = null;

                    if (object_value.get("reference")) |key_value| {
                        if (key_value == .string)
                            reference = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("name")) |key_value| {
                        if (key_value == .string)
                            name = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("description")) |key_value| {
                        if (key_value == .string)
                            description = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("type")) |key_value| {
                        if (key_value == .string)
                            action_type = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("address")) |key_value| {
                        if (key_value == .string)
                            address = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("selector")) |key_value| {
                        if (key_value == .string)
                            selector = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("value")) |key_value| {
                        if (key_value == .string)
                            value = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("script")) |key_value| {
                        if (key_value == .string)
                            script = try allocator.dupe(u8, key_value.string);
                    }

                    if (object_value.get("delay")) |key_value| {
                        if (key_value == .number) {
                            delay = @intFromFloat(key_value.number);
                        } else if (key_value == .string) {
                            delay = std.fmt.parseInt(u32, key_value.string, 10) catch null;
                        }
                    }

                    const action = Action{
                        .reference = reference.?,
                        .name = name.?,
                        .description = description.?,
                        .action_type = action_type.?,
                        .address = address,
                        .selector = selector,
                        .value = value,
                        .script = script,
                        .delay = delay,
                    };

                    try actions.append(action);
                }

                return GetActionsResult{
                    .actions = try actions.toOwnedSlice(),
                    .raw_actions = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolvePopActionResult(allocator: std.mem.Allocator, result: Response) !PopActionResult {
    if (result.status < 200 or result.status >= 300) {
        return error.InvalidResponse;
    }

    if (result.body.len == 0) {
        return error.EmptyResponse;
    }

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("action")) |action_value| {
        switch (action_value) {
            .object => |object_value| {
                var reference: ?[]const u8 = null;
                var name: ?[]const u8 = null;
                var description: ?[]const u8 = null;
                var action_type: ?[]const u8 = null;

                var address: ?[]const u8 = null;
                var selector: ?[]const u8 = null;
                var value: ?[]const u8 = null;
                var script: ?[]const u8 = null;

                var delay: ?u32 = null;

                if (object_value.get("reference")) |key_value| {
                    if (key_value == .string)
                        reference = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("name")) |key_value| {
                    if (key_value == .string)
                        name = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("description")) |key_value| {
                    if (key_value == .string)
                        description = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("type")) |key_value| {
                    if (key_value == .string)
                        action_type = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("address")) |key_value| {
                    if (key_value == .string)
                        address = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("selector")) |key_value| {
                    if (key_value == .string)
                        selector = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("value")) |key_value| {
                    if (key_value == .string)
                        value = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("script")) |key_value| {
                    if (key_value == .string)
                        script = try allocator.dupe(u8, key_value.string);
                }

                if (object_value.get("delay")) |key_value| {
                    if (key_value == .number) {
                        delay = @intFromFloat(key_value.number);
                    } else if (key_value == .string) {
                        delay = std.fmt.parseInt(u32, key_value.string, 10) catch null;
                    }
                }

                // Validate required fields
                if (reference == null) return error.MissingReference;
                if (name == null) return error.MissingName;
                if (description == null) return error.MissingDescription;
                if (action_type == null) return error.MissingActionType;

                const action = Action{
                    .reference = reference.?,
                    .name = name.?,
                    .description = description.?,
                    .action_type = action_type.?,
                    .address = address,
                    .selector = selector,
                    .value = value,
                    .script = script,
                    .delay = delay,
                };

                return PopActionResult{
                    .action = action,
                    .raw_action = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}
