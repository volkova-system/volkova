const std = @import("std");

// Command enumerates all supported CLI commands.
pub const Command = enum {
    health,
    stop,
    list,
    get,
    push,
    pop,
};

// ListParams holds validated parameters for the list command.
pub const ListParams = struct {
    skip: u32,
    limit: u32,
};

// PushParams holds validated parameters for the push command.
pub const PushParams = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    action_type: []const u8,
    address: ?[]const u8,
    selector: ?[]const u8,
    value: ?[]const u8,
    script: ?[]const u8,
    delay: ?u32,
};

// resolveCommand maps a raw string argument to a Command.
// Returns error.UnknownCommand when the string is not recognized.
pub fn resolveCommand(raw: []const u8) !Command {
    if (std.mem.eql(u8, raw, "health")) return .health;
    if (std.mem.eql(u8, raw, "stop")) return .stop;
    if (std.mem.eql(u8, raw, "list")) return .list;
    if (std.mem.eql(u8, raw, "get")) return .get;
    if (std.mem.eql(u8, raw, "push")) return .push;
    if (std.mem.eql(u8, raw, "pop")) return .pop;
    return error.UnknownCommand;
}

// resolveReference validates that a reference argument is non-empty.
// Returns error.MissingReference when absent.
pub fn resolveReference(args: []const []const u8) ![]const u8 {
    if (args.len < 1 or args[0].len == 0) {
        return error.MissingReference;
    }
    return args[0];
}

// resolveListParams parses optional skip and limit flags.
// Accepted forms: --skip=N  --limit=N
// Falls back to defaults: skip=0, limit=10.
pub fn resolveListParams(args: []const []const u8) !ListParams {
    var skip: u32 = 0;
    var limit: u32 = 10;

    for (args) |arg| {
        if (std.mem.startsWith(u8, arg, "--skip=")) {
            const raw = arg["--skip=".len..];
            skip = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidSkip;
            };
        } else if (std.mem.startsWith(u8, arg, "--limit=")) {
            const raw = arg["--limit=".len..];
            limit = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidLimit;
            };
            if (limit == 0 or limit > 100) return error.InvalidLimit;
        }
    }

    return ListParams{ .skip = skip, .limit = limit };
}

// resolvePushParams parses required and optional push flags.
// Required: --reference=  --name=  --description=  --type=
// Optional: --address=  --selector=  --value=  --script=  --delay=
pub fn resolvePushParams(
    args: []const []const u8,
) !PushParams {
    var reference: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var description: ?[]const u8 = null;
    var action_type: ?[]const u8 = null;
    var address: ?[]const u8 = null;
    var selector: ?[]const u8 = null;
    var value: ?[]const u8 = null;
    var script: ?[]const u8 = null;
    var delay: ?u32 = null;

    for (args) |arg| {
        if (std.mem.startsWith(u8, arg, "--reference=")) {
            reference = arg["--reference=".len..];
        } else if (std.mem.startsWith(u8, arg, "--name=")) {
            name = arg["--name=".len..];
        } else if (std.mem.startsWith(u8, arg, "--description=")) {
            description = arg["--description=".len..];
        } else if (std.mem.startsWith(u8, arg, "--type=")) {
            action_type = arg["--type=".len..];
        } else if (std.mem.startsWith(u8, arg, "--address=")) {
            address = arg["--address=".len..];
        } else if (std.mem.startsWith(u8, arg, "--selector=")) {
            selector = arg["--selector=".len..];
        } else if (std.mem.startsWith(u8, arg, "--value=")) {
            value = arg["--value=".len..];
        } else if (std.mem.startsWith(u8, arg, "--script=")) {
            script = arg["--script=".len..];
        } else if (std.mem.startsWith(u8, arg, "--delay=")) {
            const raw = arg["--delay=".len..];
            delay = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidDelay;
            };
        }
    }

    if (reference == null or reference.?.len == 0)
        return error.MissingReference;
    if (name == null or name.?.len == 0)
        return error.MissingName;
    if (description == null or description.?.len == 0)
        return error.MissingDescription;
    if (action_type == null or action_type.?.len == 0)
        return error.MissingType;

    return PushParams{
        .reference = reference.?,
        .name = name.?,
        .description = description.?,
        .action_type = action_type.?,
        .address = address,
        .selector = selector,
        .value = value,
        .script = script,
        .delay = delay,
    };
}
