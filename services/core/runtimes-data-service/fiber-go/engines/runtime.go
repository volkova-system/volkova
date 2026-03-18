package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/data"
	"runtimes-data-service/models"
)

// GetRuntime retrieves a single runtime from the cache by its key.
func GetRuntime(cache *data.Cache, key string) (*models.Runtime, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var runtime models.Runtime

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("runtime not found for key %s: %w",
                key, err)
		}

		if err := json.Unmarshal([]byte(val), &runtime); err != nil {
			return fmt.Errorf("failed to unmarshal runtime data: %w",
                err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &runtime, nil
}
