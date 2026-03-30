package data

import (
	"fmt"
	"sessions-data-service/settings"

	"github.com/tidwall/buntdb"
)

// SetupIndexes creates the BuntDB indexes required for session queries.
//
// Indexes created:
//   - DefaultCacheName: string index on all "session:*" keys.
//   - ReferenceIndexName: JSON index on the "reference" field,
//     used for ordered pagination in GetSessions.
//
// Returns an error if either index cannot be created.
func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"session:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"session:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
