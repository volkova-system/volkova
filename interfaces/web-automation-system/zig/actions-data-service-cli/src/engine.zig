const std = @import("std");
const handler = @import("handler.zig");
const setting = @import("setting.zig");
const request = @import("request.zig");

// fetchHealth calls GET /service/data/actions/health.
//
pub fn fetchHealth(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}/health",

        .{base_url},
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// sendStop calls POST /service/data/actions/stop.
//
pub fn sendStop(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}/stop",

        .{base_url},
    );

    defer allocator.free(url);

    return sendPost(allocator, url, "{}");
}

// fetchActions calls GET /service/data/actions?skip=N&limit=N.
//
pub fn fetchActions(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
    parameters: handler.ListParameters,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}?skip={d}&limit={d}",

        .{ base_url, parameters.skip, parameters.limit },
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// fetchAction calls GET /service/data/actions/:reference.
//
pub fn fetchAction(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
    reference: []const u8,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}/{s}",

        .{ base_url, reference },
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// pushAction calls POST /service/data/actions/push with a JSON body.
//
pub fn pushAction(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
    parameters: handler.PushParameters,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}/push",

        .{base_url},
    );

    defer allocator.free(url);

    const body = try buildPushBody(allocator, parameters);

    defer allocator.free(body);

    return sendPost(allocator, url, body);
}

// popAction calls DELETE /service/data/actions/pop/:reference.
//
pub fn popAction(
    allocator: std.mem.Allocator,
    setting_data: setting.Setting,
    reference: []const u8,
) !request.Response {
    const base_url = try setting_data.resolveBaseUrl();

    defer allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        allocator,

        "{s}/pop/{s}",

        .{ base_url, reference },
    );

    defer allocator.free(url);

    return sendDelete(allocator, url);
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
) !request.Response {
    return request.httpRequest(allocator, "GET", url, null);
}

// sendPost performs an HTTP POST request with a JSON body.
//
fn sendPost(
    allocator: std.mem.Allocator,
    url: []const u8,
    body: []const u8,
) !request.Response {
    return request.httpRequest(allocator, "POST", url, body);
}

// sendDelete performs an HTTP DELETE request.
//
fn sendDelete(
    allocator: std.mem.Allocator,
    url: []const u8,
) !request.Response {
    return request.httpRequest(allocator, "DELETE", url, null);
}
