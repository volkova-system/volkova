pub const Session = struct {
    reference: []const u8,
    storage_state: []const u8,
};

pub const Queue = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    state: []const u8,
    index: u32,
};

pub const Job = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
    schedule: []const u8,
};

pub const Task = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,
};

pub const Action = struct {
    reference: []const u8,
    name: []const u8,
    description: []const u8,

    type: []const u8,

    address: ?[]const u8,
    selector: ?[]const u8,
    value: ?[]const u8,
    script: ?[]const u8,

    delay: ?u32,
};

pub const Runtime = struct {
    reference: []const u8,

    session: Session,
    queue: Queue,
    job: Job,
    task: Task,
    action: Action,

    state_date_time: []const u8,
    state: []const u8,
    issue: ?[]const u8,

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

// PushRuntimeParameters holds validated parameters for the push command.
//
pub const PushRuntimeParameters = struct {
    reference: []const u8,

    session_reference: []const u8,
    session_storage_state: []const u8,

    queue_reference: []const u8,
    queue_name: []const u8,
    queue_description: []const u8,
    queue_state: []const u8,
    queue_index: u32,

    job_reference: []const u8,
    job_name: []const u8,
    job_description: []const u8,
    job_schedule: []const u8,

    task_reference: []const u8,
    task_name: []const u8,
    task_description: []const u8,

    action_reference: []const u8,
    action_name: []const u8,
    action_description: []const u8,
    action_type: []const u8,

    action_address: ?[]const u8,
    action_selector: ?[]const u8,
    action_value: ?[]const u8,
    action_script: ?[]const u8,
    action_delay: ?u32,

    state: []const u8,
    issue: ?[]const u8,
};

// GetRuntimeParameters holds validated parameters for the get command.
//
pub const GetRuntimeParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// GetRuntimesParameters holds validated parameters for the list command.
//
pub const GetRuntimesParameters = struct {
    skip: u32,
    limit: u32,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PopRuntimeParameters holds validated parameters for the pop command.
//
pub const PopRuntimeParameters = struct {
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

pub const PushRuntimeResult = struct {
    reference: []const u8,
};

pub const GetRuntimeResult = struct {
    runtime: Runtime,
    raw_runtime: []u8,
};

pub const GetRuntimesResult = struct {
    runtimes: []Runtime,
    raw_runtimes: []u8,
};

pub const PopRuntimeResult = struct {
    runtime: Runtime,
    raw_runtime: []u8,
};
