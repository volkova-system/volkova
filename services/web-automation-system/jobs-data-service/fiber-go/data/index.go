package data

import (
	"fmt"

	"github.com/tidwall/buntdb"
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
		buntdb.IndexJSON("reference"),
	); err != nil {
		return fmt.Errorf("failed to create reference index: %w", err)
	}

	return nil
}
