const std = @import("std");
const handler = @import("handler.zig");
const request = @import("request.zig");
const model = @import("model.zig");

const httpRequest = request.httpRequest;

const Setting = @import("setting.zig").Setting;

const Response = request.Response;

const Health = model.Health;
const Operation = model.Operation;
const Action = model.Action;

const PushActionParameters = model.PushActionParameters;
const GetActionParameters = model.GetActionParameters;
const GetActionsParameters = model.GetActionsParameters;
const PopActionParameters = model.PopActionParameters;

// checkHealth calls GET /service/data/actions/health.
//
pub fn checkHealth(setting: Setting) !Health {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/health",

        .{base_url},
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    const health_result = try handler.resolveCheckHealthResult(setting.allocator, result);

    return health_result.health;
}

// stopService calls POST /service/data/actions/stop.
//
pub fn stopService(setting: Setting) !Operation {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/stop",

        .{base_url},
    );

    defer setting.allocator.free(url);

    const result = try sendPost(setting.allocator, url, "{}");

    const operation_result = try handler.resolveStopServiceResult(setting.allocator, result);

    return operation_result.operation;
}

// pushAction calls POST /service/data/actions/push with a JSON body.
//
pub fn pushAction(
    setting: Setting,
    parameters: PushActionParameters,
) ![]const u8 {
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

    const push_action_result = try handler.resolvePushActionResult(setting.allocator, result);

    return push_action_result.reference;
}

// getAction calls GET /service/data/actions/:reference.
//
pub fn getAction(
    setting: Setting,
    parameters: GetActionParameters,
) !Action {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/{s}",

        .{ base_url, parameters.reference },
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    const get_action_result = try handler.resolveGetActionResult(setting.allocator, result);
    const action = get_action_result.action;

    const output_directory = parameters.output_directory;

    var directory = std.fs.openDirAbsolute(output_directory, .{}) catch std.fs.cwd().openDir(output_directory, .{}) catch {
        return error.InvalidOutputDirectory;
    };

    defer directory.close();

    var file = try directory.createFile(parameters.file_name, .{ .truncate = true });

    defer file.close();

    try file.writeAll(action);

    return action;
}

// getActions calls GET /service/data/actions?skip=N&limit=N.
//
pub fn getActions(
    setting: Setting,
    parameters: GetActionsParameters,
) ![]Action {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}?skip={d}&limit={d}",

        .{ base_url, parameters.skip, parameters.limit },
    );

    defer setting.allocator.free(url);

    const result = try sendGet(setting.allocator, url);

    const get_actions_result = try handler.resolveGetActionsResult(setting.allocator, result);
    const actions = get_actions_result.actions;

    const output_directory = parameters.output_directory;

    var directory = std.fs.openDirAbsolute(output_directory, .{}) catch std.fs.cwd().openDir(output_directory, .{}) catch {
        return error.InvalidOutputDirectory;
    };

    defer directory.close();

    var file = try directory.createFile(parameters.file_name, .{ .truncate = true });

    defer file.close();

    try file.writeAll(actions);

    return actions;
}

// popAction calls DELETE /service/data/actions/pop/:reference.
//
pub fn popAction(
    setting: Setting,
    parameters: PopActionParameters,
) !Action {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/pop/{s}",

        .{ base_url, parameters.reference },
    );

    defer setting.allocator.free(url);

    return sendDelete(setting.allocator, url);
}

// buildPushBody serializes PushParameters into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    parameters: handler.PushParameters,
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
