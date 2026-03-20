package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"queues-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"queue:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"queue:*",
		func(a, b string) bool {
			var queueA, queueB models.Queue

			if err := json.Unmarshal([]byte(a), &queueA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &queueB); err != nil {
				return false
			}

			return queueA.Reference < queueB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
