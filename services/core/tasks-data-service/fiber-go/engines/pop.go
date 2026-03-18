package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"tasks-data-service/data"
	"tasks-data-service/models"
)

// PopTask retrieves and removes a task from the cache by reference.
func PopTask(cache *data.Cache, reference string) (*models.Task, error) {
	if reference == "" {
		return nil, fmt.Errorf("reference cannot be empty")
	}

	key := fmt.Sprintf("task:%s", reference)
	var task models.Task

	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		value, err := tx.Get(key)
		if err != nil {
			if err == buntdb.ErrNotFound {
				return fmt.Errorf("task not found")
			}
			return fmt.Errorf("failed to get task: %w", err)
		}

		if err := json.Unmarshal([]byte(value), &task); err != nil {
			return fmt.Errorf("failed to unmarshal task: %w", err)
		}

		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to delete task: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &task, nil
}
