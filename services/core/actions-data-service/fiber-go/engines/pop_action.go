package engines

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"actions-data-service/data"
)

// PopAction removes an action from the cache by its key.
func PopAction(cache *data.Cache, key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove action with key %s: %w", key, err)
		}

		return nil
	})
}
