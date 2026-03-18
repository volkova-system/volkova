package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/data"
	"runtimes-data-service/models"
)

const defaultIndexName = "runtimes"

// GetRuntimes retrieves a paginated list of runtimes from the cache.
func GetRuntimes(cache *data.Cache, skip, limit int) ([]models.Runtime, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var runtimes []models.Runtime

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

			var runtime models.Runtime
			if err := json.Unmarshal([]byte(value), &runtime);
                err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal runtime at key %s: %w",
                        key, err)

				return false
			}

			runtimes = append(runtimes, runtime)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve runtimes: %w", err)
	}

	return runtimes, nil
}

// GetRuntimesCount returns the total number of runtimes stored in the cache.
func GetRuntimesCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count runtimes: %w", err)
	}

	return count, nil
}
