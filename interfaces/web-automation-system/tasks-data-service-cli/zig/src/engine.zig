const std = @import("std");
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

// checkHealth calls GET /service/data/tasks/health.
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

// stopService calls POST /service/data/tasks/stop.
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

// abortService calls POST /service/data/tasks/abort.
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

// startService calls POST /service/data/tasks/start.
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

// killService calls POST /service/data/tasks/kill.
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

// pushTask calls POST /service/data/tasks/push with a JSON body.
//
pub fn pushTask(
    setting: Setting,
    parameters: PushTaskParameters,
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

// getTask calls GET /service/data/tasks/:reference.
//
pub fn getTask(
    setting: Setting,
    parameters: GetTaskParameters,
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

// getTasks calls GET /service/data/tasks?skip=N&limit=N.
//
pub fn getTasks(
    setting: Setting,
    parameters: GetTasksParameters,
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

// popTask calls DELETE /service/data/tasks/pop/:reference.
//
pub fn popTask(
    setting: Setting,
    parameters: PopTaskParameters,
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

// buildPushBody serializes PushTaskParameters into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    parameters: PushTaskParameters,
) ![]u8 {
    var buffer = std.ArrayList(u8){};
    const writer = buffer.writer(allocator);

    try writer.writeAll("{");

    try writer.print(
        "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"",

        .{
            parameters.reference,
            parameters.name,
            parameters.description,
        },
    );

    if (parameters.actions.len > 0) {
        try writer.writeAll(",\"actions\":[");

        var first: bool = true;
        for (parameters.actions) |action| {
            if (!first) try writer.writeAll(",");
            first = false;

            try writer.writeAll("{");

            try writer.print(
                "\"reference\":\"{s}\"," ++
                    "\"name\":\"{s}\"," ++
                    "\"description\":\"{s}\"," ++
                    "\"flow\":\"{s}\"",

                .{
                    action.reference,
                    action.name,
                    action.description,
                    action.flow,
                },
            );

            if (action.address) |value|
                try writer.print(",\"address\":\"{s}\"", .{value});

            if (action.selector) |value|
                try writer.print(",\"selector\":\"{s}\"", .{value});

            if (action.value) |value|
                try writer.print(",\"value\":\"{s}\"", .{value});

            if (action.script) |value|
                try writer.print(",\"script\":\"{s}\"", .{value});

            if (action.delay) |value|
                try writer.print(",\"delay\":{d}", .{value});

            try writer.writeAll("}");
        }

        try writer.writeAll("]");
    }

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
