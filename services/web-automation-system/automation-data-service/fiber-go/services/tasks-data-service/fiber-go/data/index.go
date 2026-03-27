package data

import (
	"fmt"
	"tasks-data-service/settings"

	"github.com/tidwall/buntdb"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		settings.DefaultCacheName,
		"task:*",
		buntdb.IndexString,
	); err != nil {
		return fmt.Errorf("failed to create default index: %w", err)
	}

	if err := conn.CreateIndex(
		settings.ReferenceIndexName,
		"task:*",
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
