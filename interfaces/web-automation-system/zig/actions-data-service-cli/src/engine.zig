const std = @import("std");
const handler = @import("handler.zig");
const request = @import("request.zig");
const model = @import("model.zig");

const httpRequest = request.httpRequest;

const Setting = @import("setting.zig").Setting;

const Response = request.Response;

const PushActionParameters = model.PushActionParameters;
const GetActionParameters = model.GetActionParameters;
const GetActionsParameters = model.GetActionsParameters;
const PopActionParameters = model.PopActionParameters;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const PushActionResult = model.PushActionResult;
const GetActionResult = model.GetActionResult;
const GetActionsResult = model.GetActionsResult;
const PopActionResult = model.PopActionResult;

// checkHealth calls GET /service/data/actions/health.
//
pub fn checkHealth(setting: Setting) !CheckHealthResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/health",

        .{base_url},
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    return try handler.resolveCheckHealthResult(setting.allocator, result);
}

// stopService calls POST /service/data/actions/stop.
//
pub fn stopService(setting: Setting) !StopServiceResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/stop",

        .{base_url},
    );

    defer setting.allocator.free(url);

    const result = try sendPost(setting.allocator, url, "{}");

    return try handler.resolveStopServiceResult(setting.allocator, result);
}

// pushAction calls POST /service/data/actions/push with a JSON body.
//
pub fn pushAction(
    setting: Setting,
    parameters: PushActionParameters,
) !PushActionResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/push",

        .{base_url},
    );

    defer setting.allocator.free(url);

    const body = try buildPushBody(setting.allocator, parameters);

    defer setting.allocator.free(body);

    const result = try sendPost(setting.allocator, url, body);

    return try handler.resolvePushActionResult(setting.allocator, result);
}

// getAction calls GET /service/data/actions/:reference.
//
pub fn getAction(
    setting: Setting,
    parameters: GetActionParameters,
) !GetActionResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/{s}",

        .{ base_url, parameters.reference },
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);

    return try handler.resolveGetActionResult(setting.allocator, result);
}

// getActions calls GET /service/data/actions?skip=N&limit=N.
//
pub fn getActions(
    setting: Setting,
    parameters: GetActionsParameters,
) !GetActionsResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}?skip={d}&limit={d}",

        .{ base_url, parameters.skip, parameters.limit },
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);

    return try handler.resolveGetActionsResult(setting.allocator, result);
}

// popAction calls DELETE /service/data/actions/pop/:reference.
//
pub fn popAction(
    setting: Setting,
    parameters: PopActionParameters,
) !PopActionResult {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/pop/{s}",

        .{ base_url, parameters.reference },
    );

    defer setting.allocator.free(url);

    const result = try sendDelete(setting.allocator, url);

    if (parameters.output_directory) |output_directory|
        if (parameters.file_name) |file_name|
            try persistToFile(output_directory, file_name, result.body);

    return try handler.resolvePopActionResult(setting.allocator, result);
}

// buildPushBody serializes PushParameters into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    parameters: PushActionParameters,
) ![]u8 {
    var buffer = std.ArrayList(u8){};
    const writer = buffer.writer(allocator);

    try writer.writeAll("{");

    try writer.print(
        "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"," ++
            "\"type\":\"{s}\"",

        .{
            parameters.reference,
            parameters.name,
            parameters.description,
            parameters.action_type,
        },
    );

    if (parameters.address) |value|
        try writer.print(",\"address\":\"{s}\"", .{value});

    if (parameters.selector) |value|
        try writer.print(",\"selector\":\"{s}\"", .{value});

    if (parameters.value) |value|
        try writer.print(",\"value\":\"{s}\"", .{value});

    if (parameters.script) |value|
        try writer.print(",\"script\":\"{s}\"", .{value});

    if (parameters.delay) |value|
        try writer.print(",\"delay\":{d}", .{value});

    try writer.writeAll("}");

    return buffer.toOwnedSlice(allocator);
}

// sendGet performs an HTTP GET request and returns the response.
//
fn sendGet(
    allocator: std.mem.Allocator,
    url: []const u8,
) !Response {
    return httpRequest(allocator, "GET", url, null);
}

// sendPost performs an HTTP POST request with a JSON body.
//
fn sendPost(
    allocator: std.mem.Allocator,
    url: []const u8,
    body: []const u8,
) !Response {
    return httpRequest(allocator, "POST", url, body);
}

// sendDelete performs an HTTP DELETE request.
//
fn sendDelete(
    allocator: std.mem.Allocator,
    url: []const u8,
) !Response {
    return httpRequest(allocator, "DELETE", url, null);
}

fn persistToFile(
    output_directory: []const u8,
    file_name: []const u8,
    content: []u8,
) !void {
    var directory = std.fs.openDirAbsolute(output_directory, .{}) catch std.fs.cwd().openDir(output_directory, .{}) catch {
        return error.InvalidOutputDirectory;
    };

    defer directory.close();

    var file = try directory.createFile(file_name, .{ .truncate = true });

    defer file.close();

    try file.writeAll(content);

    try file.sync();
}
