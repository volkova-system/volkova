const std = @import("std");
const cli = @import("cli.zig");
const setting = @import("setting.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    defer _ = gpa.deinit();

    try cli.run(setting.load(gpa.allocator()));
}
