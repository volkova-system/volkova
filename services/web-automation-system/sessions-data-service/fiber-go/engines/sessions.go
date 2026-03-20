package engines

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"sessions-data-service/data"
	"sessions-data-service/models"
)

const defaultIndexName = "sessions"

// GetSessions retrieves a paginated list of sessions from the cache.
func GetSessions(cache *data.Cache, skip, limit int) ([]models.Session, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var sessions []models.Session

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

			var session models.Session
			if err := json.Unmarshal([]byte(value), &session); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal session at key %s: %w", key, err)

				return false
			}

			sessions = append(sessions, session)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve sessions: %w", err)
	}

	return sessions, nil
}

// GetSessionsCount returns the total number of sessions stored in the cache.
func GetSessionsCount(cache *data.Cache) (int, error) {
	var count int

	err := cache.DB().View(func(tx *buntdb.Tx) error {
		tx.Ascend(cache.Name(), func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count sessions: %w", err)
	}

	return count, nil
}
