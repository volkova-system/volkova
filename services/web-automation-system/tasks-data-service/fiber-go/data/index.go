package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"tasks-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"task:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"task:*",
		func(a, b string) bool {
			var taskA, taskB models.Task

			if err := json.Unmarshal([]byte(a), &taskA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &taskB); err != nil {
				return false
			}

			return taskA.Reference < taskB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
