package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"actions-data-service/data"
	"actions-data-service/models"
)

// GetAction retrieves a single action from the cache by its key.
func GetAction(cache *data.Cache, key string) (*models.Action, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var action models.Action

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("action not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &action); err != nil {
			return fmt.Errorf("failed to unmarshal action data: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &action, nil
}
