package engines

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"sessions-data-service/data"
)

// PopSession removes a session from the cache by its key.
func PopSession(cache *data.Cache, key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove session with key %s: %w", key, err)
		}

		return nil
	})
}
