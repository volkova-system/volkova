package engines

import (
	"encoding/json"
	"fmt"
	"time"

	"github.com/tidwall/buntdb"

	"runtimes-data-service/data"
	"runtimes-data-service/models"
)

// PushRuntime stores a runtime in the cache using its reference as the key.
//
func PushRuntime(cache *data.Cache, runtime models.Runtime) error {
	// Set timestamps for new runtimes
	now := time.Now()
	if runtime.CreatedAt.IsZero() {
		runtime.CreatedAt = now
	}
	runtime.UpdatedAt = now

	runtimeData, err := json.Marshal(runtime)
	if err != nil {
		return fmt.Errorf("failed to marshal runtime data: %w", err)
	}

	return cache.DB().Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("runtime:"+runtime.Reference,
            string(runtimeData), nil)
		if err != nil {
			return fmt.Errorf("failed to store runtime in cache: %w",
                err)
		}

		return nil
	})
}
