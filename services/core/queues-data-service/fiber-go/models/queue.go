package models

import "time"

// The queue database must always be empty.
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
}

type Task struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Actions     []Action    `json:"actions"`
}

type Action struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Type        string      `json:"type"`

    Address     *string     `json:"address,omitempty"`
    Selector    *string     `json:"selector,omitempty"`
    Value       *string     `json:"value,omitempty"`
    Script      *string     `json:"script,omitempty"`
    Delay       *int        `json:"delay,omitempty"`
}
