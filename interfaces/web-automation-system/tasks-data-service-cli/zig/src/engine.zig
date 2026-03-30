const std = @import("std");
const handler = @import("handler.zig");
const request = @import("request.zig");
const model = @import("model.zig");
const httpRequest = request.httpRequest;
const Setting = @import("setting.zig").Setting;
const Response = request.Response;
const PushTaskParameters = model.PushTaskParameters;
const GetTaskParameters = model.GetTaskParameters;
const GetTasksParameters = model.GetTasksParameters;
const PopTaskParameters = model.PopTaskParameters;
const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;
const PushTaskResult = model.PushTaskResult;
const GetTaskResult = model.GetTaskResult;
const GetTasksResult = model.GetTasksResult;
const PopTaskResult = model.PopTaskResult;

pub fn checkHealth(setting: Setting) !CheckHealthResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/health", .{base_url});
    defer setting.allocator.free(url);
    const result = try sendGet(setting.allocator, url);
    return try handler.resolveCheckHealthResult(setting.allocator, result);
}

pub fn stopService(setting: Setting) !StopServiceResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/stop", .{base_url});
    defer setting.allocator.free(url);
    const result = try sendPost(setting.allocator, url, "{}");
    return try handler.resolveStopServiceResult(setting.allocator, result);
}

pub fn abortService(setting: Setting) !AbortServiceResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/abort", .{base_url});
    defer setting.allocator.free(url);
    const result = try sendPost(setting.allocator, url, "{}");
    return try handler.resolveAbortServiceResult(setting.allocator, result);
}

pub fn startService(setting: Setting) !StartServiceResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/start", .{base_url});
    defer setting.allocator.free(url);
    const result = try sendPost(setting.allocator, url, "{}");
    return try handler.resolveStartServiceResult(setting.allocator, result);
}

pub fn killService(setting: Setting) !KillServiceResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/kill", .{base_url});
    defer setting.allocator.free(url);
    const result = try sendPost(setting.allocator, url, "{}");
    return try handler.resolveKillServiceResult(setting.allocator, result);
}

pub fn pushTask(setting: Setting, parameters: PushTaskParameters) !PushTaskResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/push", .{base_url});
    defer setting.allocator.free(url);
    const body = try buildPushBody(setting.allocator, parameters);
    defer setting.allocator.free(body);
    const result = try sendPost(setting.allocator, url, body);
    return try handler.resolvePushTaskResult(setting.allocator, result);
}

pub fn getTask(setting: Setting, parameters: GetTaskParameters) !GetTaskResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/{s}", .{ base_url, parameters.reference });
    defer setting.allocator.free(url);
    const result = try sendGet(setting.allocator, url);
    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);
    return try handler.resolveGetTaskResult(setting.allocator, result);
}

pub fn getTasks(setting: Setting, parameters: GetTasksParameters) !GetTasksResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}?skip={d}&limit={d}", .{ base_url, parameters.skip, parameters.limit });
    defer setting.allocator.free(url);
    const result = try sendGet(setting.allocator, url);
    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);
    return try handler.resolveGetTasksResult(setting.allocator, result);
}

pub fn popTask(setting: Setting, parameters: PopTaskParameters) !PopTaskResult {
    const base_url = try setting.resolveBaseUrl();
    defer setting.allocator.free(base_url);
    const url = try std.fmt.allocPrint(setting.allocator, "{s}/pop/{s}", .{ base_url, parameters.reference });
    defer setting.allocator.free(url);
    const result = try sendDelete(setting.allocator, url);
    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);
    return try handler.resolvePopTaskResult(setting.allocator, result);
}

fn buildPushBody(allocator: std.mem.Allocator, parameters: PushTaskParameters) ![]u8 {
    var buffer = std.ArrayList(u8){};
    const writer = buffer.writer(allocator);
    try writer.writeAll("{");
    try writer.print("\"reference\":\"{s}\",\"name\":\"{s}\",\"description\":\"{s}\"", .{ parameters.reference, parameters.name, parameters.description });
    if (parameters.actions.len > 0) {
        try writer.writeAll(",\"actions\":[");
        var first: bool = true;
        for (parameters.actions) |action| {
            if (!first) try writer.writeAll(",");
            first = false;
            try writer.writeAll("{");
            try writer.print("\"reference\":\"{s}\",\"name\":\"{s}\",\"description\":\"{s}\",\"flow\":\"{s}\"", .{ action.reference, action.name, action.description, action.flow });
            if (action.address) |value| try writer.print(",\"address\":\"{s}\"", .{value});
            if (action.selector) |value| try writer.print(",\"selector\":\"{s}\"", .{value});
            if (action.value) |value| try writer.print(",\"value\":\"{s}\"", .{value});
            if (action.script) |value| try writer.print(",\"script\":\"{s}\"", .{value});
            if (action.delay) |value| try writer.print(",\"delay\":{d}", .{value});
            try writer.writeAll("}");
        }
        try writer.writeAll("]");
    }
    try writer.writeAll("}");
    return buffer.toOwnedSlice(allocator);
}

fn sendGet(allocator: std.mem.Allocator, url: []const u8) !Response {
    return httpRequest(allocator, "GET", url, null);
}

fn sendPost(allocator: std.mem.Allocator, url: []const u8, body: []const u8) !Response {
    return httpRequest(allocator, "POST", url, body);
}

fn sendDelete(allocator: std.mem.Allocator, url: []const u8) !Response {
    return httpRequest(allocator, "DELETE", url, null);
}

fn persistToFile(output_directory: []const u8, file_name: []const u8, content: []u8) !void {
    var directory = std.fs.openDirAbsolute(output_directory, .{}) catch std.fs.cwd().openDir(output_directory, .{}) catch {
        return error.InvalidOutputDirectory;
    };
    defer directory.close();
    var file = try directory.createFile(file_name, .{ .truncate = true });
    defer file.close();
    try file.writeAll(content);
    try file.sync();
}
