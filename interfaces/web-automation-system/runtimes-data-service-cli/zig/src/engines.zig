const std = @import("std");
const request = @import("request.zig");
const model = @import("models.zig");

const httpRequest = request.httpRequest;

const Setting = @import("settings.zig").Setting;

const Response = request.Response;

const PushRuntimeParameters = model.PushRuntimeParameters;
const GetRuntimeParameters = model.GetRuntimeParameters;
const GetRuntimesParameters = model.GetRuntimesParameters;
const PopRuntimeParameters = model.PopRuntimeParameters;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

const PushRuntimeResult = model.PushRuntimeResult;
const GetRuntimeResult = model.GetRuntimeResult;
const GetRuntimesResult = model.GetRuntimesResult;
const PopRuntimeResult = model.PopRuntimeResult;

// checkHealth calls GET /service/data/runtimes/health.
//
pub fn checkHealth(setting: Setting) !Response {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/health",

        .{base_url},
    );

    defer setting.allocator.free(url);

    return try sendGet(setting.allocator, url);
}

// stopService calls POST /service/data/runtimes/stop.
//
pub fn stopService(setting: Setting) !Response {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/stop",

        .{base_url},
    );

    defer setting.allocator.free(url);

    return try sendPost(setting.allocator, url, "{}");
}

// abortService calls POST /service/data/runtimes/abort.
//
pub fn abortService(setting: Setting) !Response {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/abort",

        .{base_url},
    );

    defer setting.allocator.free(url);

    return try sendPost(setting.allocator, url, "{}");
}

// startService calls POST /service/data/runtimes/start.
//
pub fn startService(setting: Setting) !Response {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/start",

        .{base_url},
    );

    defer setting.allocator.free(url);

    return try sendPost(setting.allocator, url, "{}");
}

// killService calls POST /service/data/runtimes/kill.
//
pub fn killService(setting: Setting) !Response {
    const base_url = try setting.resolveBaseUrl();

    defer setting.allocator.free(base_url);

    const url = try std.fmt.allocPrint(
        setting.allocator,

        "{s}/kill",

        .{base_url},
    );

    defer setting.allocator.free(url);

    return try sendPost(setting.allocator, url, "{}");
}

// pushRuntime calls POST /service/data/runtimes/push with a JSON body.
//
pub fn pushRuntime(
    setting: Setting,
    parameters: PushRuntimeParameters,
) !Response {
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

    return try sendPost(setting.allocator, url, body);
}

// getRuntime calls GET /service/data/runtimes/:reference.
//
pub fn getRuntime(
    setting: Setting,
    parameters: GetRuntimeParameters,
) !Response {
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

    return result;
}

// getRuntimes calls GET /service/data/runtimes?skip=N&limit=N.
//
pub fn getRuntimes(
    setting: Setting,
    parameters: GetRuntimesParameters,
) !Response {
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

    return result;
}

// popRuntime calls DELETE /service/data/runtimes/pop/:reference.
//
pub fn popRuntime(
    setting: Setting,
    parameters: PopRuntimeParameters,
) !Response {
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

    return result;
}

// buildPushBody serializes PushRuntimeParameters into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    parameters: PushRuntimeParameters,
) ![]u8 {
    var buffer = std.ArrayList(u8){};
    const writer = buffer.writer(allocator);

    try writer.writeAll("{");

    try writer.print(
        "\"reference\":\"{s}\"," ++
            "\"session\":{{" ++
            "\"reference\":\"{s}\"," ++
            "\"storage_state\":\"{s}\"" ++
            "}}," ++
            "\"queue\":{{" ++
            "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"," ++
            "\"state\":\"{s}\"," ++
            "\"index\":{d}" ++
            "}}," ++
            "\"job\":{{" ++
            "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"," ++
            "\"schedule\":\"{s}\"" ++
            "}}," ++
            "\"task\":{{" ++
            "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"" ++
            "}}," ++
            "\"action\":{{" ++
            "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"," ++
            "\"type\":\"{s}\"",

        .{
            parameters.reference,
            parameters.session_reference,
            parameters.session_storage_state,
            parameters.queue_reference,
            parameters.queue_name,
            parameters.queue_description,
            parameters.queue_state,
            parameters.queue_index,
            parameters.job_reference,
            parameters.job_name,
            parameters.job_description,
            parameters.job_schedule,
            parameters.task_reference,
            parameters.task_name,
            parameters.task_description,
            parameters.action_reference,
            parameters.action_name,
            parameters.action_description,
            parameters.action_type,
        },
    );

    if (parameters.action_address) |value|
        try writer.print(",\"address\":\"{s}\"", .{value});

    if (parameters.action_selector) |value|
        try writer.print(",\"selector\":\"{s}\"", .{value});

    if (parameters.action_value) |value|
        try writer.print(",\"value\":\"{s}\"", .{value});

    if (parameters.action_script) |value|
        try writer.print(",\"script\":\"{s}\"", .{value});

    if (parameters.action_delay) |value|
        try writer.print(",\"delay\":{d}", .{value});

    try writer.print(
        "}}," ++
            "\"state\":\"{s}\"",
        .{parameters.state},
    );

    if (parameters.issue) |value|
        try writer.print(",\"issue\":\"{s}\"", .{value});

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
