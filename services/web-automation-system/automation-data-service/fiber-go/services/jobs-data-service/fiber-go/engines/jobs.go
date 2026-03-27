package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
	"jobs-data-service/models"
)

// GetJobs retrieves a paginated list of jobs from the cache.
func GetJobs(cache *data.Cache, skip, limit int) ([]models.Job, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var jobs []models.Job

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend("reference", func(key, value string) bool {
			if count < skip {
				count++

				return true
			}

			if collected >= limit {
				return false
			}

			var job models.Job
			if err := json.Unmarshal([]byte(value), &job); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal job at key %s: %w", key, err)

				return false
			}

			jobs = append(jobs, job)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve jobs: %w", err)
	}

	return jobs, nil
}

// GetJobsCount returns the total number of jobs stored in the cache.
func GetJobsCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count jobs: %w", err)
	}

	return count, nil
}
