package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"queues-data-service/data"
	"queues-data-service/models"
)

// PushQueue stores a queue in the cache using its reference as the key.
//
func PushQueue(cache *data.Cache, queue models.Queue) error {
	// Set timestamps for new queues
	now := time.Now()
	if queue.CreatedAt.IsZero() {
		queue.CreatedAt = now
	}
	queue.UpdatedAt = now

	queueData, err := json.Marshal(queue)
	if err != nil {
		return fmt.Errorf("failed to marshal queue data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("queue:"+queue.Reference, string(queueData), nil)
		if err != nil {
			return fmt.Errorf("failed to store queue in cache: %w", err)
		}

		return nil
	})
}
