package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"sessions-data-service/data"
	"sessions-data-service/models"
)

// PopSession removes a session from the cache by its key and returns
// the retrieved data.
func PopSession(cache *data.Cache, key string) (*models.Session, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var session models.Session
	err := cache.DB().Update(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("session not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &session); err != nil {
			return fmt.Errorf("failed to unmarshal session data: %w", err)
		}

		_, err = tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove session with key %s: %w", key, err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &session, nil
}
