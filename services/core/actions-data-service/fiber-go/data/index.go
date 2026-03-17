package data

import (
	"encoding/json"

	"github.com/tidwall/buntdb"

	"actions-data-service/models"
)

func SetupIndexes(conn *buntdb.DB) error {
	if err := conn.CreateIndex(
		defaultCacheName,
		"action:*",
		buntdb.IndexString,
	); err != nil {
		return err
	}

	if err := conn.CreateIndex(
		"reference",
		"action:*",
		func(a, b string) bool {
			var actionA, actionB models.Action

			json.Unmarshal([]byte(a), &actionA)
			json.Unmarshal([]byte(b), &actionB)

			return actionA.Reference < actionB.Reference
		},
	); err != nil {
		return err
	}

	return nil
}
