// Package models defines the data structures used across the service.
package models

import "time"

// Queue represents a single web-automation queue stored in the cache.
//
// Required fields: Reference, Name.
// Timestamps are managed by the engine layer:
//   - CreatedAt is set once on first push.
//   - UpdatedAt is refreshed on every push.
type Queue struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Job   Job    `json:"job"`
	State string `json:"state"`
	Index int    `json:"index"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Job represents the automation job associated with a queue entry.
type Job struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Tasks []Task `json:"tasks"`

	// Schedule must be a valid cron expression.
	Schedule string `json:"schedule"`
}

// Task represents a single automation task within a job.
type Task struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Actions []Action `json:"actions"`
}

// Action represents a single automation step within a task.
type Action struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	// Type identifies the automation step type (e.g. click, navigate).
	Type string `json:"type"`

	Address  *string `json:"address,omitempty"`
	Selector *string `json:"selector,omitempty"`
	Value    *string `json:"value,omitempty"`
	Script   *string `json:"script,omitempty"`
	Delay    *int    `json:"delay,omitempty"`
}
