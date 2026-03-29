package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"tasks-data-service/data"
	"tasks-data-service/models"
)

// PushTask stores a task in the cache using its reference as the key.
// If the task has no CreatedAt timestamp it is set to now; UpdatedAt is
// always refreshed to the current time.
//
// The cache key format is "task:<reference>".
// Returns an error if marshalling or the BuntDB write fails.
func PushTask(cache *data.Cache, task models.Task) error {
	// Set timestamps for new tasks
	now := time.Now()
	if task.CreatedAt.IsZero() {
		task.CreatedAt = now
	}
	task.UpdatedAt = now

	taskData, err := json.Marshal(task)
	if err != nil {
		return fmt.Errorf("failed to marshal task data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("task:"+task.Reference, string(taskData), nil)
		if err != nil {
			return fmt.Errorf("failed to store task in cache: %w", err)
		}

		return nil
	})
}
