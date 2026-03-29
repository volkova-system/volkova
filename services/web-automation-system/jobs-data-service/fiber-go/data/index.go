package data

import (
	"fmt"
	"jobs-data-service/settings"

	"github.com/tidwall/buntdb"
)

// SetupIndexes creates the BuntDB indexes required for job queries.
//
// Indexes created:
//   - DefaultCacheName: string index on all "job:*" keys.
//   - ReferenceIndexName: JSON index on the "reference" field,
//     used for ordered pagination in GetJobs.
//
// Returns an error if either index cannot be created.
func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"job:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"job:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
