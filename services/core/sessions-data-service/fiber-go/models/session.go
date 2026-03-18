package models

import (
	"encoding/json"
	"time"
)

type Session struct {
    Reference       string          `json:"reference"`

    StorageState    json.RawMessage `json:"storage_state"`

    CreatedAt       time.Time       `json:"created_at"`
    UpdatedAt       time.Time       `json:"updated_at"`
}
