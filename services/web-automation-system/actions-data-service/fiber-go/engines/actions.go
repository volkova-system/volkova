package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"actions-data-service/data"
	"actions-data-service/models"
)

// GetActions retrieves a paginated list of actions from the cache.
func GetActions(cache *data.Cache, skip, limit int) ([]models.Action, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var actions []models.Action

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(cache.Name(), func(key, value string) bool {
			if count < skip {
				count++

				return true
			}

			if collected >= limit {
				return false
			}

			var action models.Action
			if err := json.Unmarshal([]byte(value), &action); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal action at key %s: %w", key, err)

				return false
			}

			actions = append(actions, action)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve actions: %w", err)
	}

	return actions, nil
}

// GetActionsCount returns the total number of actions stored in the cache.
func GetActionsCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count actions: %w", err)
	}

	return count, nil
}
