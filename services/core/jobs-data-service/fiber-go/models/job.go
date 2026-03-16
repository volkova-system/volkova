package models

import "time"

// A job must be executed only once in queue
// A job is a set of tasks that can be executed immediately or on a schedule
type Job struct {
    Reference   string      `json:"reference"`
    Name        string      `json:"name"`
    Description string      `json:"description"`

    Tasks       []Task      `json:"tasks"`

    // Schedule must be a valid cron expression
    // If schedule is empty then it is immediately executed
    // else it must follow the schedule
    Schedule    *string      `json:"schedule,omitempty"`

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
