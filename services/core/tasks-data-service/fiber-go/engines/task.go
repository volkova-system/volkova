package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"tasks-data-service/data"
	"tasks-data-service/models"
)

// GetTask retrieves a single task from the cache by its key.
func GetTask(cache *data.Cache, key string) (*models.Task, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var task models.Task

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("task not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &task); err != nil {
			return fmt.Errorf("failed to unmarshal task data: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &task, nil
}
