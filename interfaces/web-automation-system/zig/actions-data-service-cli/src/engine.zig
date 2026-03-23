const std = @import("std");
const handler = @import("handler.zig");
const setting = @import("setting.zig");

// Response wraps the raw HTTP response body.
// Caller owns the body slice.
//
pub const Response = struct {
    status: u16,
    body: []u8,
};

// fetchHealth calls GET /service/data/actions/health.
//
pub fn fetchHealth(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/health",
        .{base},
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// sendStop calls POST /service/data/actions/stop.
//
pub fn sendStop(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/stop",
        .{base},
    );

    defer allocator.free(url);

    return sendPost(allocator, url, "{}");
}

// fetchActions calls GET /service/data/actions?skip=N&limit=N.
//
pub fn fetchActions(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
    params: handler.ListParams,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}?skip={d}&limit={d}",
        .{ base, params.skip, params.limit },
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// fetchAction calls GET /service/data/actions/:reference.
//
pub fn fetchAction(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
    reference: []const u8,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/{s}",
        .{ base, reference },
    );

    defer allocator.free(url);

    return sendGet(allocator, url);
}

// pushAction calls POST /service/data/actions/push with a JSON body.
//
pub fn pushAction(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
    params: handler.PushParams,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/push",
        .{base},
    );

    defer allocator.free(url);

    const body = try buildPushBody(allocator, params);

    defer allocator.free(body);

    return sendPost(allocator, url, body);
}

// popAction calls DELETE /service/data/actions/pop/:reference.
//
pub fn popAction(
    allocator: std.mem.Allocator,
    setting: setting.Setting,
    reference: []const u8,
) !Response {
    const base = try setting.resolveBaseUrl();

    defer allocator.free(base);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}/pop/{s}",
        .{ base, reference },
    );
    defer allocator.free(url);

    return sendDelete(allocator, url);
}

// buildPushBody serializes PushParams into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    params: handler.PushParams,
) ![]u8 {
    var buffer = std.ArrayList(u8).init(allocator);
    const writer = buffer.writer();

    try writer.writeAll("{");
    try writer.print(
        "\"reference\":\"{s}\",\"name\":\"{s}\"," ++
            "\"description\":\"{s}\",\"type\":\"{s}\"",
        .{
            params.reference,
            params.name,
            params.description,
            params.action_type,
        },
    );

    if (params.address) |value|
        try writer.print(",\"address\":\"{s}\"", .{value});
    if (params.selector) |value|
        try writer.print(",\"selector\":\"{s}\"", .{value});
    if (params.value) |value|
        try writer.print(",\"value\":\"{s}\"", .{value});
    if (params.script) |value|
        try writer.print(",\"script\":\"{s}\"", .{value});
    if (params.delay) |value|
        try writer.print(",\"delay\":{d}", .{value});

    try writer.writeAll("}");

    return buf.toOwnedSlice();
}

// sendGet performs an HTTP GET request and returns the response.
fn sendGet(
    allocator: std.mem.Allocator,
    url: []const u8,
) !Response {
    return httpRequest(allocator, "GET", url, null);
}

// sendPost performs an HTTP POST request with a JSON body.
fn sendPost(
    allocator: std.mem.Allocator,
    url: []const u8,
    body: []const u8,
) !Response {
    return httpRequest(allocator, "POST", url, body);
}

// sendDelete performs an HTTP DELETE request.
fn sendDelete(
    allocator: std.mem.Allocator,
    url: []const u8,
) !Response {
    return httpRequest(allocator, "DELETE", url, null);
}

// httpRequest is the single HTTP transport procedure.
// Caller owns Response.body.
fn httpRequest(
    allocator: std.mem.Allocator,
    method: []const u8,
    url: []const u8,
    body: ?[]const u8,
) !Response {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);

    var header_buffer: [4096]u8 = undefined;
    var request = try client.request(
        std.http.Method.parse(method),
        uri,
        .{ .server_header_buffer = &header_buffer },
    );
    defer request.deinit();

    if (body) |body_value| {
        request.transfer_encoding = .{ .content_length = body_value.len };
        request.headers.content_type =
            .{ .override = "application/json" };
    }

    try request.send();

    if (body) |body_value| {
        try request.writeAll(body_value);
        try request.finish();
    }

    try request.wait();

    const status: u16 = @intFromEnum(request.response.status);
    const response_body = try request.reader()
        .readAllAlloc(
            allocator,
            1024 * 1024,
        );

    return Response{ .status = status, .body = response_body };
}
