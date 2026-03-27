package models

import "time"

// A job must be executed only once in queue
// A job is a set of tasks that can be executed immediately or on a schedule
type Job struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Tasks []Task `json:"tasks"`

	// Schedule must be a valid cron expression
	// If schedule is empty then it is immediately executed
	// else it must follow the schedule
	Schedule *string `json:"schedule,omitempty"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}

type Task struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Actions []Action `json:"actions"`
}

type Action struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Flow string `json:"flow"`

	Address  *string `json:"address,omitempty"`
	Selector *string `json:"selector,omitempty"`
	Value    *string `json:"value,omitempty"`
	Script   *string `json:"script,omitempty"`
	Delay    *int    `json:"delay,omitempty"`
}
