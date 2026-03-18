package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"runtime:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"runtime:*",
		func(a, b string) bool {
			var runtimeA, runtimeB models.Runtime

			if err := json.Unmarshal([]byte(a), &runtimeA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &runtimeB); err != nil {
				return false
			}

			return runtimeA.Reference < runtimeB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
