package data

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"sessions-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"session:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		"reference",
		"session:*",
		func(a, b string) bool {
			var sessionA, sessionB models.Session

			if err := json.Unmarshal([]byte(a), &sessionA); err != nil {
				return false
			}
			if err := json.Unmarshal([]byte(b), &sessionB); err != nil {
				return false
			}

			return sessionA.Reference < sessionB.Reference
		},
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
