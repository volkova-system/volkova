package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"actions-data-service/data"
	"actions-data-service/models"
)

// PushAction stores an action in the cache using its reference as the key.
//
func PushAction(cache *data.Cache, action models.Action) error {
	// Set timestamps for new actions
	now := time.Now()
	if action.CreatedAt.IsZero() {
		action.CreatedAt = now
	}
	action.UpdatedAt = now

	actionData, err := json.Marshal(action)
	if err != nil {
		return fmt.Errorf("failed to marshal action data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("action:"+action.Reference, string(actionData), nil)
		if err != nil {
			return fmt.Errorf("failed to store action in cache: %w", err)
		}

		return nil
	})
}
