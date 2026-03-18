package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"sessions-data-service/data"
	"sessions-data-service/models"
)

// PushSession stores a session in the cache using its reference as the key.
//
func PushSession(cache *data.Cache, session models.Session) error {
	// Set timestamps for new sessions
	now := time.Now()
	if session.CreatedAt.IsZero() {
		session.CreatedAt = now
	}
	session.UpdatedAt = now

	sessionData, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("failed to marshal session data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("session:"+session.Reference, string(sessionData), nil)
		if err != nil {
			return fmt.Errorf("failed to store session in cache: %w", err)
		}

		return nil
	})
}
