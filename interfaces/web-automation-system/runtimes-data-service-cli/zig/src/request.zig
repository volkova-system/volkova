const std = @import("std");

// Response wraps the raw HTTP response body.
// Caller owns the body slice.
//
pub const Response = struct {
    status: u16,
    body: []u8,
};

// httpRequest is the single HTTP transport procedure.
// Caller owns Response.body.
//
pub fn httpRequest(
    allocator: std.mem.Allocator,
    method: []const u8,
    url: []const u8,
    body: ?[]const u8,
) !Response {
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = std.Uri.parse(url) catch |error_value| switch (error_value) {
        error.InvalidFormat => return error.InvalidUrl,
        else => return error_value,
    };

    const http_method = parseHttpMethod(method) orelse return error.UnsupportedHttpMethod;

    var response_writer = std.Io.Writer.Allocating.init(allocator);
    defer response_writer.deinit();

    var redirect_buffer: [4096]u8 = undefined;

    const result = client.fetch(.{
        .location = .{ .uri = uri },
        .method = http_method,
        .redirect_buffer = &redirect_buffer,
        .response_writer = &response_writer.writer,
        .payload = body,
    }) catch |error_value| switch (error_value) {
        error.ConnectionRefused => return error.ConnectionFailed,
        error.NetworkUnreachable => return error.NetworkError,
        error.UnknownHostName => return error.DnsResolutionFailed,
        error.TlsInitializationFailed => return error.TlsError,
        error.CertificateBundleLoadFailure => return error.CertificateError,
        error.OutOfMemory => return error.OutOfMemory,
        else => return error_value,
    };

    const status: u16 = @intFromEnum(result.status);
    const result_body = response_writer.toOwnedSlice() catch |error_value| switch (error_value) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return error_value,
    };

    return Response{ .status = status, .body = result_body };
}

// Helper function to parse HTTP method strings
fn parseHttpMethod(method: []const u8) ?std.http.Method {
    const method_map = std.StaticStringMap(std.http.Method).initComptime(.{
        .{ "GET", .GET },
        .{ "POST", .POST },
        .{ "PUT", .PUT },
        .{ "DELETE", .DELETE },
        .{ "PATCH", .PATCH },
        .{ "HEAD", .HEAD },
        .{ "OPTIONS", .OPTIONS },
    });
    return method_map.get(method);
}
