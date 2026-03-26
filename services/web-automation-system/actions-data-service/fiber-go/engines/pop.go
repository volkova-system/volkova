package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"actions-data-service/data"
	"actions-data-service/models"
)

// PopAction removes an action from the cache by its key and returns
// the retrieved data.
func PopAction(cache *data.Cache, key string) (*models.Action, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var action models.Action
	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("action not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &action); err != nil {
			return fmt.Errorf("failed to unmarshal action data: %w", err)
		}

		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove action with key %s: %w", key, err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &action, nil
}
