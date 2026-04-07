package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"queues-data-service/data"
	"queues-data-service/models"
)

// PopQueue removes a queue from the cache by its key and returns
// the retrieved data.
func PopQueue(cache *data.Cache, key string) (*models.Queue, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var queue models.Queue
	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		// First retrieve the data
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("queue not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &queue); err != nil {
			return fmt.Errorf("failed to unmarshal queue data: %w", err)
		}

		// Then delete the key
		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove queue with key %s: %w", key, err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &queue, nil
}
