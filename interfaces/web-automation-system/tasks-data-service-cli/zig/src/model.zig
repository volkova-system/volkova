pub const Action = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    flow: []const u8,
    address: ?[]const u8,
    selector: ?[]const u8,
    value: ?[]const u8,
    script: ?[]const u8,
    delay: ?u32,
};

pub const Task = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    actions: []Action,
    created_at: []const u8,
    updated_at: []const u8,
};

pub const Health = struct {
    status: []const u8,
};

pub const Operation = struct {
    status: []const u8,
    procedure: []const u8,
    service: []const u8,
};

pub const Command = enum {
    health,
    stop,
    abort,
    start,
    kill,
    list,
    get,
    push,
    pop,
};

pub const PushTaskParameters = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    actions: []Action,
};

pub const GetTaskParameters = struct {
    reference: []const u8,
    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

pub const GetTasksParameters = struct {
    skip: u32,
    limit: u32,
    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

pub const PopTaskParameters = struct {
    reference: []const u8,
    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

pub const PushTaskResult = struct {
    reference: []const u8,
};

pub const GetTaskResult = struct {
    task: Task,
    raw_task: []u8,
};

pub const GetTasksResult = struct {
    tasks: []Task,
    raw_tasks: []u8,
};

pub const PopTaskResult = struct {
    task: Task,
    raw_task: []u8,
};

pub const CheckHealthResult = struct {
    health: Health,
    raw_health: []u8,
};

pub const StopServiceResult = struct {
    operation: Operation,
    raw_operation: []u8,
};

pub const AbortServiceResult = struct {
    operation: Operation,
    raw_operation: []u8,
};

pub const StartServiceResult = struct {
    operation: Operation,
    raw_operation: []u8,
};

pub const KillServiceResult = struct {
    operation: Operation,
    raw_operation: []u8,
};
