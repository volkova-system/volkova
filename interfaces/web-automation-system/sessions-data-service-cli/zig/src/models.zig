pub const Session = struct {
    reference: []const u8,
    storage_state: []const u8,

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

// PushSessionParameters holds validated parameters for the push command.
//
pub const PushSessionParameters = struct {
    reference: []const u8,
    storage_state: []const u8,
};

// GetSessionParameters holds validated parameters for the get command.
//
pub const GetSessionParameters = struct {
    reference: []const u8,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// GetSessionsParameters holds validated parameters for the list command.
//
pub const GetSessionsParameters = struct {
    skip: u32,
    limit: u32,

    output_directory: ?[]const u8,
    file_name: ?[]const u8,
};

// PopSessionParameters holds validated parameters for the pop command.
//
pub const PopSessionParameters = struct {
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

pub const PushSessionResult = struct {
    reference: []const u8,
};

pub const GetSessionResult = struct {
    session: Session,
    raw_session: []u8,
};

pub const GetSessionsResult = struct {
    sessions: []Session,
    raw_sessions: []u8,
};

pub const PopSessionResult = struct {
    session: Session,
    raw_session: []u8,
};
