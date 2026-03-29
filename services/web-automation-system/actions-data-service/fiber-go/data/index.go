package data

import (
	"actions-data-service/settings"
	"fmt"

	"github.com/tidwall/buntdb"
)

// SetupIndexes creates the BuntDB indexes required for action queries.
//
// Indexes created:
//   - DefaultCacheName: string index on all "action:*" keys.
//   - ReferenceIndexName: JSON index on the "reference" field,
//     used for ordered pagination in GetActions.
//
// Returns an error if either index cannot be created.
func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"action:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"action:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
