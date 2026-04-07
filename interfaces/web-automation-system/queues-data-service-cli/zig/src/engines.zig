const std = @import("std");
const request = @import("request.zig");
const model = @import("models.zig");

const httpRequest = request.httpRequest;

const Setting = @import("settings.zig").Setting;

const Response = request.Response;

const PushQueueParameters = model.PushQueueParameters;
const GetQueueParameters = model.GetQueueParameters;
const GetQueuesParameters = model.GetQueuesParameters;
const PopQueueParameters = model.PopQueueParameters;

const CheckHealthResult = model.CheckHealthResult;
const StopServiceResult = model.StopServiceResult;
const AbortServiceResult = model.AbortServiceResult;
const StartServiceResult = model.StartServiceResult;
const KillServiceResult = model.KillServiceResult;

const PushQueueResult = model.PushQueueResult;
const GetQueueResult = model.GetQueueResult;
const GetQueuesResult = model.GetQueuesResult;
const PopQueueResult = model.PopQueueResult;

// checkHealth calls GET /service/data/queues/health.
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

// stopService calls POST /service/data/queues/stop.
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

// abortService calls POST /service/data/queues/abort.
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

// startService calls POST /service/data/queues/start.
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

// killService calls POST /service/data/queues/kill.
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

// pushQueue calls POST /service/data/queues/push with a JSON body.
//
pub fn pushQueue(
    setting: Setting,
    parameters: PushQueueParameters,
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

// getQueue calls GET /service/data/queues/:reference.
//
pub fn getQueue(
    setting: Setting,
    parameters: GetQueueParameters,
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

// getQueues calls GET /service/data/queues?skip=N&limit=N.
//
pub fn getQueues(
    setting: Setting,
    parameters: GetQueuesParameters,
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

// popQueue calls DELETE /service/data/queues/pop/:reference.
//
pub fn popQueue(
    setting: Setting,
    parameters: PopQueueParameters,
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

// buildPushBody serializes PushQueueParameters into a JSON string.
// Caller owns the returned slice.
//
fn buildPushBody(
    allocator: std.mem.Allocator,
    parameters: PushQueueParameters,
) ![]u8 {
    var buffer = std.ArrayList(u8){};
    const writer = buffer.writer(allocator);

    try writer.writeAll("{");

    try writer.print(
        "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"," ++
            "\"state\":\"{s}\"," ++
            "\"index\":{d}",

        .{
            parameters.reference,
            parameters.name,
            parameters.description,
            parameters.state,
            parameters.index,
        },
    );

    // Add job object
    try writer.writeAll(",\"job\":{");

    try writer.print(
        "\"reference\":\"{s}\"," ++
            "\"name\":\"{s}\"," ++
            "\"description\":\"{s}\"",

        .{
            parameters.job.reference,
            parameters.job.name,
            parameters.job.description,
        },
    );

    if (parameters.job.schedule) |schedule_value|
        try writer.print(",\"schedule\":\"{s}\"", .{schedule_value});

    if (parameters.job.tasks.len > 0) {
        try writer.writeAll(",\"tasks\":[");

        var first_task: bool = true;
        for (parameters.job.tasks) |task| {
            if (!first_task) try writer.writeAll(",");
            first_task = false;

            try writer.writeAll("{");

            try writer.print(
                "\"reference\":\"{s}\"," ++
                    "\"name\":\"{s}\"," ++
                    "\"description\":\"{s}\"",

                .{
                    task.reference,
                    task.name,
                    task.description,
                },
            );

            if (task.actions.len > 0) {
                try writer.writeAll(",\"actions\":[");

                var first_action: bool = true;
                for (task.actions) |action| {
                    if (!first_action) try writer.writeAll(",");
                    first_action = false;

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
        }

        try writer.writeAll("]");
    }

    try writer.writeAll("}"); // Close job object

    try writer.writeAll("}"); // Close main object

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
