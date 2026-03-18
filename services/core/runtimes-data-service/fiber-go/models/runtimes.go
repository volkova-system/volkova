package models

import "time"

type Runtime struct {
    Reference       string          `json:"reference"`

    Queue           Queue           `json:"queue"`
    Job             Job             `json:"job"`
    Task            Task            `json:"task"`
    Action          Action          `json:"action"`

    // State can only be "doing", "done", "aborted", and "failed"
    // If the action was aborted means an issue occurred and the runtime
    // was stopped in the middle of the process.
    // If the action failed it means the action finished but it does not
    // meet the criteria and issue must be recorded
    StateDateTime   time.Time       `json:"state_date_time"`
    State           string          `json:"state"`
    Issue           *string         `json:"issue,omitempty"`

    CreatedAt       time.Time       `json:"created_at"`
    UpdatedAt       time.Time       `json:"updated_at"`
}

type Queue struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Job         Job         `json:"job"`
    State       string      `json:"state"`
    Index       int         `json:"index"`

    CreatedAt   time.Time   `json:"created_at"`
    UpdatedAt   time.Time   `json:"updated_at"`
}

type Job struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Tasks       []Task      `json:"tasks"`

    // Schedule must be a valid cron expression
    Schedule    string      `json:"schedule"`

    CreatedAt   time.Time   `json:"created_at"`
    UpdatedAt   time.Time   `json:"updated_at"`
}

type Task struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Actions     []Action    `json:"actions"`

    CreatedAt   time.Time   `json:"created_at"`
    UpdatedAt   time.Time   `json:"updated_at"`
}

type Action struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Type        string      `json:"type"`

    Selector    *string     `json:"selector,omitempty"`
    Value       *string     `json:"value,omitempty"`
    Address     *string     `json:"address,omitempty"`
    Delay       *int        `json:"delay,omitempty"`
    Script      *string     `json:"script,omitempty"`

    CreatedAt   time.Time   `json:"created_at"`
    UpdatedAt   time.Time   `json:"updated_at"`
}
