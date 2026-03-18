package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"queues-data-service/data"
	"queues-data-service/models"
)

const defaultIndexName = "queues"

// GetQueues retrieves a paginated list of queues from the cache.
func GetQueues(cache *data.Cache, skip, limit int) ([]models.Queue, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var queues []models.Queue

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(cache.Name(), func(key, value string) bool {
			if count < skip {
				count++

				return true
			}

			if collected >= limit {
				return false
			}

			var queue models.Queue
			if err := json.Unmarshal([]byte(value), &queue); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal queue at key %s: %w", key, err)

				return false
			}

			queues = append(queues, queue)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve queues: %w", err)
	}

	return queues, nil
}

// GetQueuesCount returns the total number of queues stored in the cache.
func GetQueuesCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count queues: %w", err)
	}

	return count, nil
}
