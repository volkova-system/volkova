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
};

pub const Job = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,

    tasks: []Task,

    schedule: ?[]const u8,

    created_at: []const u8,
    updated_at: []const u8,
};

pub const Queue = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,

    job: Job,
    state: []const u8,
    index: u32,

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

// Command enumerates all supported CLI commands.
//
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

// PushQueueParameters holds validated parameters for the push command.
//
pub const PushQueueParameters = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,

    job: Job,
    state: []const u8,
    index: u32,
};

// GetQueueParameters holds validated parameters for the get command.
//
pub const GetQueueParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// GetQueuesParameters holds validated parameters for the list command.
//
pub const GetQueuesParameters = struct {
    skip: u32,
    limit: u32,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PopQueueParameters holds validated parameters for the pop command.
//
pub const PopQueueParameters = struct {
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

pub const PushQueueResult = struct {
    reference: []const u8,
};

pub const GetQueueResult = struct {
    queue: Queue,
    raw_queue: []u8,
};

pub const GetQueuesResult = struct {
    queues: []Queue,
    raw_queues: []u8,

    skip: u32,
    limit: u32,
    total: u32,
    pages: u32,
    page: u32,
};

pub const PopQueueResult = struct {
    queue: Queue,
    raw_queue: []u8,
};
