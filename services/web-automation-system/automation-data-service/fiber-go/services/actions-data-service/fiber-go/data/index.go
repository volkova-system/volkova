package data

import (
	"actions-data-service/settings"
	"fmt"

	"github.com/tidwall/buntdb"
)

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
