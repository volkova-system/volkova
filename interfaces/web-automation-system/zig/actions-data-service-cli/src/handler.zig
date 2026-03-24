const std = @import("std");

// Command enumerates all supported CLI commands.
//
pub const Command = enum {
    health,
    stop,

    list,
    get,
    push,
    pop,
};

// ListParameters holds validated parameters for the list command.
//
pub const ListParameters = struct {
    skip: u32,
    limit: u32,
    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PushParameters holds validated parameters for the push command.
//
pub const PushParameters = struct {
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
//
pub fn resolveCommand(raw: []const u8) !Command {
    if (std.mem.eql(u8, raw, "health"))
        return .health;

    if (std.mem.eql(u8, raw, "stop"))
        return .stop;

    if (std.mem.eql(u8, raw, "list"))
        return .list;

    if (std.mem.eql(u8, raw, "get"))
        return .get;

    if (std.mem.eql(u8, raw, "push"))
        return .push;

    if (std.mem.eql(u8, raw, "pop"))
        return .pop;

    return error.UnknownCommand;
}

// resolveReference validates that a reference argument is non-empty.
// Returns error.MissingReference when absent.
//
pub fn resolveReference(arguments: []const []const u8) ![]const u8 {
    if (arguments.len < 1 or arguments[0].len == 0) {
        return error.MissingReference;
    }

    return arguments[0];
}

// GetParams holds validated parameters for the get command.
//
pub const GetParameters = struct {
    reference: []const u8,
    output_directory: ?[]const u8,
    file_name: []const u8,
};

// resolveGetParameters parses required reference and optional output flags.
// Required: reference
// Optional: --output=DIR
//
pub fn resolveGetParameters(arguments: []const []const u8) !GetParameters {
    var reference: ?[]const u8 = null;
    var output_directory: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];

            if (output_directory) |value|
                if (value.len == 0)
                    return error.InvalidOutputDirectory;
        } else if (reference == null and
            !std.mem.startsWith(u8, argument_value, "--"))
        {
            reference = argument_value;
        }
    }

    if (reference == null or reference.?.len == 0)
        return error.MissingReference;

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(&file_name_buffer, "action-{s}.json", .{reference.?}) catch "action.json";

    return GetParameters{
        .reference = reference.?,
        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolveListParameters parses optional skip, limit, and output flags.
// Accepted forms: --skip=N  --limit=N  --output=DIR
// Falls back to defaults: skip=0, limit=10, output_dir=null.
//
pub fn resolveListParameters(arguments: []const []const u8) !ListParameters {
    var skip: u32 = 0;
    var limit: u32 = 10;
    var output_directory: ?[]const u8 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--skip=")) {
            const raw = argument_value["--skip=".len..];

            skip = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidSkip;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--limit=")) {
            const raw = argument_value["--limit=".len..];

            limit = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidLimit;
            };
        } else if (std.mem.startsWith(u8, argument_value, "--output=")) {
            output_directory = argument_value["--output=".len..];

            if (output_directory) |directory_value|
                if (directory_value.len == 0)
                    return error.InvalidOutputDirectory;
        }
    }

    var file_name_buffer: [256]u8 = undefined;
    const file_name = std.fmt.bufPrint(
        &file_name_buffer,
        "actions-{d}-{d}.json",
        .{ skip, limit },
    ) catch "actions.json";

    return ListParameters{
        .skip = skip,
        .limit = limit,
        .output_directory = output_directory,
        .file_name = file_name,
    };
}

// resolvePushParams parses required and optional push flags.
// Required: --reference=  --name=  --description=  --type=
// Optional: --address=  --selector=  --value=  --script=  --delay=
//
pub fn resolvePushParameters(
    allocator: std.mem.Allocator,
    arguments: []const []const u8,
) !PushParameters {
    var action_file: ?[]const u8 = null;

    var reference: ?[]const u8 = null;
    var name: ?[]const u8 = null;
    var description: ?[]const u8 = null;

    var action_type: ?[]const u8 = null;

    var address: ?[]const u8 = null;
    var selector: ?[]const u8 = null;
    var value: ?[]const u8 = null;
    var script: ?[]const u8 = null;

    var delay: ?u32 = null;

    for (arguments) |argument_value| {
        if (std.mem.startsWith(u8, argument_value, "--action=")) {
            action_file = argument_value["--action=".len..];

            return try resolvePushParametersFromFile(allocator, action_file.?);
        } else if (std.mem.startsWith(u8, argument_value, "--reference=")) {
            reference = argument_value["--reference=".len..];

            if (reference) |reference_value|
                if (reference_value.len == 0)
                    return error.InvalidReference;
        } else if (std.mem.startsWith(u8, argument_value, "--name=")) {
            name = argument_value["--name=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--description=")) {
            description = argument_value["--description=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--type=")) {
            action_type = argument_value["--type=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--address=")) {
            address = argument_value["--address=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--selector=")) {
            selector = argument_value["--selector=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--value=")) {
            value = argument_value["--value=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--script=")) {
            script = argument_value["--script=".len..];
        } else if (std.mem.startsWith(u8, argument_value, "--delay=")) {
            const raw = argument_value["--delay=".len..];

            delay = std.fmt.parseInt(u32, raw, 10) catch {
                return error.InvalidDelay;
            };
        }
    }

    return PushParameters{
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

fn resolvePushParametersFromFile(
    allocator: std.mem.Allocator,
    path: []const u8,
) !PushParameters {
    var file = std.fs.openFileAbsolute(path, .{}) catch std.fs.cwd().openFile(path, .{}) catch {
        return error.InvalidActionFile;
    };

    defer file.close();

    const content = try file.readToEndAlloc(allocator, 1024 * 1024);

    defer allocator.free(content);

    var parsed_json = try std.json.parseFromSlice(std.json.Value, allocator, content, .{});

    defer parsed_json.deinit();

    switch (parsed_json.value) {
        .object => |object_value| {
            var reference: ?[]const u8 = null;
            var name: ?[]const u8 = null;
            var description: ?[]const u8 = null;
            var action_type: ?[]const u8 = null;

            var address: ?[]const u8 = null;
            var selector: ?[]const u8 = null;
            var value: ?[]const u8 = null;
            var script: ?[]const u8 = null;

            var delay: ?u32 = null;

            if (object_value.get("reference")) |key_value| {
                if (key_value == .string)
                    reference = try allocator.dupe(u8, key_value.string);

                if (reference) |reference_value|
                    if (reference_value.len == 0)
                        return error.InvalidReference;
            }

            if (object_value.get("name")) |key_value| {
                if (key_value == .string)
                    name = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("description")) |key_value| {
                if (key_value == .string)
                    description = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("type")) |key_value| {
                if (key_value == .string)
                    action_type = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("address")) |key_value| {
                if (key_value == .string)
                    address = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("selector")) |key_value| {
                if (key_value == .string)
                    selector = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("value")) |key_value| {
                if (key_value == .string)
                    value = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("script")) |key_value| {
                if (key_value == .string)
                    script = try allocator.dupe(u8, key_value.string);
            }

            if (object_value.get("delay")) |key_value| {
                if (key_value == .string) {
                    delay = std.fmt.parseInt(u32, key_value.string, 10) catch return error.InvalidDelay;
                }
            }

            return PushParameters{
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
        },

        else => return error.InvalidActionFile,
    }
}
