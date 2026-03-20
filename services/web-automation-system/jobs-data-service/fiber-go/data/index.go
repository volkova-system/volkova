package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"jobs-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"job:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"job:*",
		func(a, b string) bool {
			var jobA, jobB models.Job

			if err := json.Unmarshal([]byte(a), &jobA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &jobB); err != nil {
				return false
			}

			return jobA.Reference < jobB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
