const std = @import("std");
const cli = @import("cli.zig");
const setting = @import("settings.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    const parameters = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, parameters);

    try cli.run(
        setting.load(allocator),
        parameters,
    );
}
