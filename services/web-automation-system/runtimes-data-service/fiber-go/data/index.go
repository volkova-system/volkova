package data

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/settings"
)

// SetupIndexes creates the BuntDB indexes required for runtime queries.
//
// Indexes created:
//   - DefaultCacheName: string index on all "runtime:*" keys.
//   - ReferenceIndexName: JSON index on the "reference" field,
//     used for ordered pagination in GetRuntimes.
//
// Returns an error if either index cannot be created.
func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"runtime:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"runtime:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
