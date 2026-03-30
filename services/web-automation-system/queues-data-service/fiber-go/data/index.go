package data

import (
	"fmt"
	"queues-data-service/settings"

	"github.com/tidwall/buntdb"
)

// SetupIndexes creates the BuntDB indexes required for queue queries.
//
// Indexes created:
//   - DefaultCacheName: string index on all "queue:*" keys.
//   - ReferenceIndexName: JSON index on the "reference" field,
//     used for ordered pagination in GetQueues.
//
// Returns an error if either index cannot be created.
func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"queue:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"queue:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
