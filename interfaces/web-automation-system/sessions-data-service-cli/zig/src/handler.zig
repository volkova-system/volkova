const std = @import("std");
const model = @import("model.zig");

const Setting = @import("setting.zig").Setting;
const Response = @import("request.zig").Response;

const Command = model.Command;
const Session = model.Session;

const PushSessionParameters = model.PushSessionParameters;
const GetSessionParameters = model.GetSessionParameters;
const GetSessionsParameters = model.GetSessionsParameters;
const PopSessionParameters = model.PopSessionParameters;

const Health = model.Health;
const Operation = model.Operation;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

const PushSessionResult = model.PushSessionResult;
const GetSessionResult = model.GetSessionResult;
const GetSessionsResult = model.GetSessionsResult;
const PopSessionResult = model.PopSessionResult;

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

pub fn resolvePushSessionParameters(setting: Setting, arguments: []const []const u8) !PushSessionParameters {
    var session_file: ?[]const u8 = null;
    var reference: ?[]const u8 = null;
    var storage_state: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--session=")) {
            session_file = argument_value["--session=".len..];
            return try resolvePushSessionParametersFromFile(setting.allocator, session_file.?);
        } else if (std.mem.startsWith(u8, argument_value, "--reference=")) {
            reference = argument_value["--reference=".len..];
            if (reference) |reference_value| if (reference_value.len == 0) return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--storage-state=")) {
            storage_state = argument_value["--storage-state=".len..];
        }
    }

    if (reference == null) return error.MissingReference;
    if (storage_state == null) return error.MissingStorageState;

    return PushSessionParameters{
        .reference = reference.?,
        .storage_state = storage_state.?,
    };
}

fn resolvePushSessionParametersFromFile(allocator: std.mem.Allocator, path: []const u8) !PushSessionParameters {
    var file = std.fs.openFileAbsolute(path, .{}) catch std.fs.cwd().openFile(path, .{}) catch {
        return error.InvalidSessionFile;
    };
    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);
    defer allocator.free(content);

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, content, .{});
    defer parsed_json.deinit();

    switch (parsed_json.value) {
        .object => |object_value| {
            var reference: ?[]const u8 = null;
            var storage_state: ?[]const u8 = null;

            if (object_value.get("reference")) |key_value| {
                if (key_value == .string) reference = try allocator.dupe(u8, key_value.string);
                if (reference) |reference_value|
                    if (reference_value.len == 0) return error.InvalidReference;
            }

            if (object_value.get("storage_state")) |key_value| {
                // Storage state can be an object or string, serialize it
                var buffer = std.ArrayList(u8){};
                defer buffer.deinit(allocator);

                try std.json.stringify(key_value, .{}, buffer.writer(allocator));
                storage_state = try buffer.toOwnedSlice(allocator);
            }

            if (reference == null) return error.MissingReference;
            if (storage_state == null) return error.MissingStorageState;

            return PushSessionParameters{
                .reference = reference.?,
                .storage_state = storage_state.?,
            };
        },
        else => return error.InvalidSessionFile,
    }
}

pub fn resolveGetSessionParameters(arguments: []const []const u8) !GetSessionParameters {
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

    const file_name = std.fmt.bufPrint(&file_name_buffer, "session-{s}.json", .{reference.?}) catch "session.json";
    return GetSessionParameters{ .reference = reference.?, .output_directory = output_directory, .file_name = file_name };
}

pub fn resolveGetSessionsParameters(arguments: []const []const u8) !GetSessionsParameters {
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

            if (output_directory) |directory_value|
                if (directory_value.len == 0) return error.InvalidOutputDirectory;
        }
    }

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "sessions-{d}-{d}.json", .{ skip, limit }) catch "sessions.json";
    return GetSessionsParameters{ .skip = skip, .limit = limit, .output_directory = output_directory, .file_name = file_name };
}

pub fn resolvePopSessionParameters(arguments: []const []const u8) !PopSessionParameters {
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
    const file_name = std.fmt.bufPrint(&file_name_buffer, "session-{s}.json", .{reference.?}) catch "session.json";
    return PopSessionParameters{ .reference = reference.?, .output_directory = output_directory, .file_name = file_name };
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

pub fn resolvePushSessionResult(setting: Setting, result: Response) !PushSessionResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    var reference: ?[]const u8 = null;

    if (parsed_json.value.object.get("reference")) |key_value| {
        if (key_value == .string)
            reference = try setting.allocator.dupe(u8, key_value.string);
    }

    if (reference == null) return error.MissingSessionReference;

    return PushSessionResult{
        .reference = reference.?,
    };
}

pub fn resolveGetSessionResult(setting: Setting, result: Response) !GetSessionResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("session")) |session_value| {
        switch (session_value) {
            .object => |object_value| {
                const session = try resolveSessionFromObject(setting.allocator, object_value);

                return GetSessionResult{
                    .session = session,
                    .raw_session = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolveGetSessionsResult(setting: Setting, result: Response) !GetSessionsResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("sessions")) |sessions_value| {
        switch (sessions_value) {
            .array => |array_value| {
                var sessions: std.ArrayList(Session) = .empty;
                defer sessions.deinit(setting.allocator);

                for (array_value.items) |session_json| {
                    if (session_json != .object) continue;
                    const session = try resolveSessionFromObject(setting.allocator, session_json.object);
                    try sessions.append(setting.allocator, session);
                }

                return GetSessionsResult{
                    .sessions = try sessions.toOwnedSlice(setting.allocator),
                    .raw_sessions = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

pub fn resolvePopSessionResult(setting: Setting, result: Response) !PopSessionResult {
    if (result.status < 200 or result.status >= 300) return error.InvalidResponse;
    if (result.body.len == 0) return error.EmptyResponse;

    var parsed_json = try std.json.parseFromSlice(std.json.Value, setting.allocator, result.body, .{});
    defer parsed_json.deinit();

    if (parsed_json.value.object.get("session")) |session_value| {
        switch (session_value) {
            .object => |object_value| {
                const session = try resolveSessionFromObject(setting.allocator, object_value);

                return PopSessionResult{
                    .session = session,
                    .raw_session = result.body,
                };
            },
            else => return error.InvalidJsonFormat,
        }
    } else {
        return error.InvalidJsonFormat;
    }
}

fn resolveSessionFromObject(allocator: std.mem.Allocator, object_value: std.json.ObjectMap) !Session {
    var reference: ?[]const u8 = null;
    var storage_state: ?[]const u8 = null;
    var created_at: ?[]const u8 = null;
    var updated_at: ?[]const u8 = null;

    if (object_value.get("reference")) |key_value| {
        if (key_value == .string)
            reference = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("storage_state")) |key_value| {
        // Storage state can be an object or string, serialize it
        var buffer = std.ArrayList(u8){};
        defer buffer.deinit(allocator);

        try std.json.stringify(key_value, .{}, buffer.writer(allocator));
        storage_state = try buffer.toOwnedSlice(allocator);
    }

    if (object_value.get("created_at")) |key_value| {
        if (key_value == .string)
            created_at = try allocator.dupe(u8, key_value.string);
    }

    if (object_value.get("updated_at")) |key_value| {
        if (key_value == .string)
            updated_at = try allocator.dupe(u8, key_value.string);
    }

    if (reference == null) return error.MissingReference;
    if (storage_state == null) return error.MissingStorageState;

    return Session{
        .reference = reference.?,
        .storage_state = storage_state.?,
        .created_at = created_at orelse "",
        .updated_at = updated_at orelse "",
    };
}
