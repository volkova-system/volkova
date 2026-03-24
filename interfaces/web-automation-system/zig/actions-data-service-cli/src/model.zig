const Action = struct {
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

pub const Health = struct {
    status: []const u8,
    service: []const u8,
    issue: ?[]const u8,
};

pub const Operation = struct {
    status: []const u8,
    type: []const u8,
    service: []const u8,
};

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

// PushActionParameters holds validated parameters for the push command.
//
pub const PushActionParameters = struct {
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

// GetActionParameters holds validated parameters for the get command.
//
pub const GetActionParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// GetActionsParameters holds validated parameters for the list command.
//
pub const GetActionsParameters = struct {
    skip: u32,
    limit: u32,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PopActionParameters holds validated parameters for the pop command.
//
pub const PopActionParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

pub const CheckHealthResult = struct {
    health: Health,
    raw_health: []u8,
};

pub const StopServiceResult = struct {
    operation: Operation,
    raw_operation: []u8,
};

pub const PushActionResult = struct {
    reference: []const u8,
};

pub const GetActionResult = struct {
    action: Action,
    raw_action: []u8,
};

pub const GetActionsResult = struct {
    actions: []Action,
    raw_actions: []u8,
};

pub const PopActionResult = struct {
    action: Action,
    raw_action: []u8,
};
