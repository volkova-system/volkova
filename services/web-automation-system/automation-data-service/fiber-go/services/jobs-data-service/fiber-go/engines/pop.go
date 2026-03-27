package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
	"jobs-data-service/models"
)

// PopJob removes a job from the cache by its key and returns
// the retrieved data.
func PopJob(cache *data.Cache, key string) (*models.Job, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var job models.Job
	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("job not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &job); err != nil {
			return fmt.Errorf("failed to unmarshal job data: %w", err)
		}

		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove job with key %s: %w", key, err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &job, nil
}
