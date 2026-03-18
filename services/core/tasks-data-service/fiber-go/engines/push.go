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
	// Set timestamps for new actions
	now := time.Now()
	if task.CreatedAt.IsZero() {
		task.CreatedAt = now
	}
	task.UpdatedAt = now

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
