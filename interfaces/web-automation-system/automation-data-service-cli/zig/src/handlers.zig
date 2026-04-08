const std = @import("std");
const model = @import("models.zig");

const Setting = @import("settings.zig").Setting;
const Response = @import("request.zig").Response;

const Command = model.Command;
const Health = model.Health;
const Operation = model.Operation;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

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

    if (std.mem.eql(u8, raw, "actions")) return .actions;
    if (std.mem.eql(u8, raw, "tasks")) return .tasks;
    if (std.mem.eql(u8, raw, "jobs")) return .jobs;
    if (std.mem.eql(u8, raw, "queues")) return .queues;
    if (std.mem.eql(u8, raw, "sessions")) return .sessions;
    if (std.mem.eql(u8, raw, "runtimes")) return .runtimes;

    return error.UnknownCommand;
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
