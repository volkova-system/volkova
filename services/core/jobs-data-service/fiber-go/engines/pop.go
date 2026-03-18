package engines

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
)

// PopJob removes a job from the cache by its key.
func PopJob(cache *data.Cache, key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove job with key %s: %w", key, err)
		}

		return nil
	})
}
