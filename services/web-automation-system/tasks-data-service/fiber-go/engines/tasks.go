package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"tasks-data-service/data"
	"tasks-data-service/models"
	"tasks-data-service/settings"
)

// GetTasks retrieves a paginated list of tasks from the cache.
func GetTasks(cache *data.Cache, skip, limit int) ([]models.Task, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var tasks []models.Task

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(settings.ReferenceIndexName, func(key, value string) bool {
			if count < skip {
				count++

				return true
			}

			if collected >= limit {
				return false
			}

			var task models.Task
			if err := json.Unmarshal([]byte(value), &task); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal task at key %s: %w", key, err)

				return false
			}

			tasks = append(tasks, task)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve tasks: %w", err)
	}

	return tasks, nil
}

// GetTasksCount returns the total number of tasks stored in the cache.
func GetTasksCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count tasks: %w", err)
	}

	return count, nil
}
