package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"queues-data-service/data"
	"queues-data-service/models"
)

// GetQueue retrieves a single queue from the cache by its key.
func GetQueue(cache *data.Cache, key string) (*models.Queue, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var queue models.Queue

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("queue not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &queue); err != nil {
			return fmt.Errorf("failed to unmarshal queue data: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &queue, nil
}
