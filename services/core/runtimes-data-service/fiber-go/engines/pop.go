package engines

import (
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/data"
)

// PopRuntime removes a runtime from the cache by its key.
//
func PopRuntime(cache *data.Cache, key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove runtime with key %s: %w",
                key, err)
		}

		return nil
	})
}
