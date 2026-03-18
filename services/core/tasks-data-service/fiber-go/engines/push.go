package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"tasks-data-service/data"
	"tasks-data-service/models"

	"github.com/tidwall/buntdb"
)

// PushTask stores a new task in the cache.
func PushTask(cache *data.Cache, task models.Task) error {
	if task.Reference == "" {
		return fmt.Errorf("task reference cannot be empty")
	}

	// Set timestamps
	now := time.Now()
	task.CreatedAt = now
	task.UpdatedAt = now

	// Set timestamps for actions
	for i := range task.Actions {
		task.Actions[i].CreatedAt = now
		task.Actions[i].UpdatedAt = now
	}

	key := fmt.Sprintf("task:%s", task.Reference)

	taskJSON, err := json.Marshal(task)
	if err != nil {
		return fmt.Errorf("failed to marshal task: %w", err)
	}

	err = cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set(key, string(taskJSON), nil)
		return err
	})

	if err != nil {
		return fmt.Errorf("failed to store task: %w", err)
	}

	return nil
}
