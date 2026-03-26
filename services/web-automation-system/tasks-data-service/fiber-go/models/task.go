package models

import "time"

type Task struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	Actions []Action `json:"actions"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
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
