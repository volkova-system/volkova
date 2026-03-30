// Package models defines the data structures used across the service.
package models

import (
	"encoding/json"
	"time"
)

// Session represents a single web-automation session stored in the cache.
//
// Required fields: Reference, StorageState.
//
// Timestamps are managed by the engine layer:
//   - CreatedAt is set once on first push.
//   - UpdatedAt is refreshed on every push.
type Session struct {
	Reference    string          `json:"reference"`
	StorageState json.RawMessage `json:"storage_state"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
