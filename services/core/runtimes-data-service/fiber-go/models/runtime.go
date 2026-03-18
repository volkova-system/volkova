package models

import (
	"encoding/json"
	"time"
)

type Runtime struct {
    Reference       string          `json:"reference"`

    Session         Session         `json:"session"`
    Queue           Queue           `json:"queue"`
    Job             Job             `json:"job"`
    Task            Task            `json:"task"`
    Action          Action          `json:"action"`

    // State can only be "idle", "doing", "done", "aborted", and "failed"
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

type Session struct {
    Reference       string          `json:"reference"`

    StorageState    json.RawMessage `json:"storage_state"`
}

type Queue struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    State       string      `json:"state"`
    Index       int         `json:"index"`
}

type Job struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    // Schedule must be a valid cron expression
    Schedule    string      `json:"schedule"`
}

type Task struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`
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
}
