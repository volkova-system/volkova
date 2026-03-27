package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
	"jobs-data-service/models"
)

// GetJob retrieves a single job from the cache by its key.
func GetJob(cache *data.Cache, key string) (*models.Job, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var job models.Job

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("job not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &job); err != nil {
			return fmt.Errorf("failed to unmarshal job data: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &job, nil
}
