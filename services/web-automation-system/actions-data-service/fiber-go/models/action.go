// Package models defines the data structures used across the service.
package models

import "time"

// Action represents a single web-automation action stored in the cache.
//
// Required fields: Reference, Name, Flow.
// Optional fields are pointer types and omitted from JSON when nil.
//
// Timestamps are managed by the engine layer:
//   - CreatedAt is set once on first push.
//   - UpdatedAt is refreshed on every push.
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

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
