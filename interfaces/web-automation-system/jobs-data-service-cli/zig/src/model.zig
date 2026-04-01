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

// PushJobParameters holds validated parameters for the push command.
//
pub const PushJobParameters = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,

    schedule: ?[]const u8,

    tasks: []Task,
};

// GetJobParameters holds validated parameters for the get command.
//
pub const GetJobParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// GetJobsParameters holds validated parameters for the list command.
//
pub const GetJobsParameters = struct {
    skip: u32,
    limit: u32,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PopJobParameters holds validated parameters for the pop command.
//
pub const PopJobParameters = struct {
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

pub const PushJobResult = struct {
    reference: []const u8,
};

pub const GetJobResult = struct {
    job: Job,
    raw_job: []u8,
};

pub const GetJobsResult = struct {
    jobs: []Job,
    raw_jobs: []u8,

    skip: u32,
    limit: u32,
    total: u32,
    pages: u32,
    page: u32,
};

pub const PopJobResult = struct {
    job: Job,
    raw_job: []u8,
};
