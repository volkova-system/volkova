// Package models defines the data structures used across the service.
package models

import "time"

// Job represents a single web-automation job stored in the cache.
//
// Required fields: Reference, Name.
// Optional fields are pointer types and omitted from JSON when nil.
//
// Timestamps are managed by the engine layer:
//   - CreatedAt is set once on first push.
//   - UpdatedAt is refreshed on every push.
//
// A job must be executed only once in queue.
// A job is a set of tasks that can be executed immediately or on a schedule.
type Job struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Tasks []Task `json:"tasks"`

	// Schedule must be a valid cron expression.
	// If schedule is empty then it is immediately executed,
	// else it must follow the schedule.
	Schedule *string `json:"schedule,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

// Task represents a named group of actions within a Job.
type Task struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Actions []Action `json:"actions"`
}

// Action represents a single web-automation step within a Task.
type Action struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	// Flow identifies the automation step type (e.g. click, navigate).
	Flow string `json:"flow"`

	Address  *string `json:"address,omitempty"`
	Selector *string `json:"selector,omitempty"`
	Value    *string `json:"value,omitempty"`
	Script   *string `json:"script,omitempty"`
	Delay    *int    `json:"delay,omitempty"`
}
