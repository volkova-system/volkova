package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/data"
	"runtimes-data-service/models"
)

// PopRuntime removes a runtime from the cache by its key and returns
// the retrieved data.
//
func PopRuntime(cache *data.Cache, key string) (*models.Runtime, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var runtime models.Runtime
	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		// First retrieve the data
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("runtime not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &runtime); err != nil {
			return fmt.Errorf("failed to unmarshal runtime data: %w", err)
		}

		// Then delete the key
		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove runtime with key %s: %w",
				key, err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &runtime, nil
}
