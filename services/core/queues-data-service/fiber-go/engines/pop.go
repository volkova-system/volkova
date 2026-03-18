package engines

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"queues-data-service/data"
)

// PopQueue removes a queue from the cache by its key.
func PopQueue(cache *data.Cache, key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove queue with key %s: %w", key, err)
		}

		return nil
	})
}
