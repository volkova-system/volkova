package models

import "time"

type Data struct {
	Reference   string `json:"reference"`
	Name        string `json:"name"`
	Description string `json:"description"`

	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
}
