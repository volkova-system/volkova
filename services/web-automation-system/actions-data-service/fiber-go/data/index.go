package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"actions-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"action:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"action:*",
		func(a, b string) bool {
			var actionA, actionB models.Action

			if err := json.Unmarshal([]byte(a), &actionA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &actionB); err != nil {
				return false
			}

			return actionA.Reference < actionB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
