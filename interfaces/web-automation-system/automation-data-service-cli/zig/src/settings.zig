const std = @import("std");

// default service host
pub const default_host: []const u8 = "http://localhost";

// default service port
pub const default_port: []const u8 = "4070";

// default automation route prefix
pub const route_prefix: []const u8 = "/service/data/automation";

// Setting holds resolved runtime configuration
//
pub const Setting = struct {
    host: []const u8,
    port: []const u8,

    allocator: std.mem.Allocator,

    // resolveBaseUrl builds the base URL from host and port.
    // Caller owns the returned slice.
    pub fn resolveBaseUrl(
        self: Setting,
    ) ![]u8 {
        return std.fmt.allocPrint(
            self.allocator,

            "{s}:{s}{s}",

            .{
                self.host,
                self.port,
                route_prefix,
            },
        );
    }
};

// load reads AUTOMATION_DATA_SERVICE_HOST and
// AUTOMATION_DATA_SERVICE_PORT from the environment.
// Falls back to defaults when variables are absent.
//
pub fn load(allocator: std.mem.Allocator) Setting {
    const host = std.process.getEnvVarOwned(
        allocator,
        "AUTOMATION_DATA_SERVICE_HOST",
    ) catch default_host;

    const port = std.process.getEnvVarOwned(
        allocator,
        "AUTOMATION_DATA_SERVICE_PORT",
    ) catch default_port;

    return Setting{
        .host = host,
        .port = port,
        .allocator = allocator,
    };
}
