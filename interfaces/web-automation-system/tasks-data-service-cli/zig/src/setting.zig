const std = @import("std");

pub const default_host: []const u8 = "http://localhost";
pub const default_port: []const u8 = "4072";
pub const route_prefix: []const u8 = "/service/data/tasks";

pub const Setting = struct {
    host: []const u8,
    port: []const u8,
    allocator: std.mem.Allocator,
    pub fn resolveBaseUrl(self: Setting) ![]u8 {
        return std.fmt.allocPrint(self.allocator, "{s}:{s}{s}", .{ self.host, self.port, route_prefix });
    }
};

pub fn load(allocator: std.mem.Allocator) Setting {
    const host = std.process.getEnvVarOwned(allocator, "TASKS_DATA_SERVICE_HOST") catch default_host;
    const port = std.process.getEnvVarOwned(allocator, "TASKS_DATA_SERVICE_PORT") catch default_port;
    return Setting{ .host = host, .port = port, .allocator = allocator };
}
