package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
	"jobs-data-service/models"
)

// PushJob stores a job in the cache using its reference as the key.
//
func PushJob(cache *data.Cache, job models.Job) error {
	// Set timestamps for new jobs
	now := time.Now()
	if job.CreatedAt.IsZero() {
		job.CreatedAt = now
	}
	job.UpdatedAt = now

	jobData, err := json.Marshal(job)
	if err != nil {
		return fmt.Errorf("failed to marshal job data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("job:"+job.Reference, string(jobData), nil)
		if err != nil {
			return fmt.Errorf("failed to store job in cache: %w", err)
		}

		return nil
	})
}
