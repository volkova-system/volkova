// Package models defines the data structures used across the service.
package models

import (
	"encoding/json"
	"time"
)

// Runtime represents a single web-automation runtime stored in the cache.
//
// Required fields: Reference, State.
// Optional fields are pointer types and omitted from JSON when nil.
//
// Timestamps are managed by the engine layer:
//   - CreatedAt is set once on first push.
//   - UpdatedAt is refreshed on every push.
type Runtime struct {
	Reference string `json:"reference"`

	Session Session `json:"session"`
	Queue   Queue   `json:"queue"`
	Job     Job     `json:"job"`
	Task    Task    `json:"task"`
	Action  Action  `json:"action"`

	// State can only be "idle", "doing", "done", "aborted", and "failed".
	// If the action was aborted means an issue occurred and the runtime
	// was stopped in the middle of the process.
	// If the action failed it means the action finished but it does not
	// meet the criteria and issue must be recorded.
	StateDateTime time.Time `json:"state_date_time"`
	State         string    `json:"state"`
	Issue         *string   `json:"issue,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Session struct {
	Reference string `json:"reference"`

	StorageState json.RawMessage `json:"storage_state"`
}

type Queue struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	State string `json:"state"`
	Index int    `json:"index"`
}

type Job struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	// Schedule must be a valid cron expression.
	Schedule string `json:"schedule"`
}

type Task struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`
}

type Action struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Type string `json:"type"`

	Address  *string `json:"address,omitempty"`
	Selector *string `json:"selector,omitempty"`
	Value    *string `json:"value,omitempty"`
	Script   *string `json:"script,omitempty"`
	Delay    *int    `json:"delay,omitempty"`
}
