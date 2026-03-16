// Package data provides an in-memory caching layer for action data using BuntDB.
// It offers efficient storage and retrieval of action information with indexing
// capabilities for optimized queries.
package data

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"

	"github.com/tidwall/buntdb"

	"actions-data-service/models"
)

// defaultCacheName is the default index name used for action storage.
const defaultCacheName = "actions"

// Cache represents an in-memory cache for action data using BuntDB.
type Cache struct {
	name    string
	actions *buntdb.DB
}

// Open creates and initializes a new in-memory cache instance.
func Open() (*Cache, error) {
	if path := os.Getenv("ACTIONS_CACHE_PATH"); path != "" {
		return OpenWithPath(path)
	}

	return OpenWithPath(":memory:")
}

func OpenWithPath(dbPath string) (*Cache, error) {
	if dbPath == "" {
		dbPath = ":memory:"
	}

	var conn *buntdb.DB
	var err error

	if dbPath == ":memory:" {
		conn, err = buntdb.Open(":memory:")
		if err != nil {
			return nil, err
		}
	} else {
		if err := os.MkdirAll(filepath.Dir(dbPath), 0755); err != nil {
			return nil, fmt.Errorf("failed to create directory for db: %w", err)
		}

		conn, err = buntdb.Open(dbPath)
		if err != nil {
			return nil, err
		}
	}

	err = conn.CreateIndex(
		defaultCacheName,
		"action:*",
		buntdb.IndexString,
	)
	if err != nil {
		return nil, err
	}

	err = conn.CreateIndex(
		"reference",
		"action:*",
		func(a, b string) bool {
			var actionA, actionB models.Action

			json.Unmarshal([]byte(a), &actionA)
			json.Unmarshal([]byte(b), &actionB)

			return actionA.Reference < actionB.Reference
		},
	)
	if err != nil {
		return nil, err
	}

	return &Cache{name: defaultCacheName, actions: conn}, nil
}

// Close gracefully shuts down the cache and releases all resources.
func (db *Cache) Close() error {
	return db.actions.Close()
}

// PushAction stores an action in the cache using its reference as the key.
func (db *Cache) PushAction(action models.Action) error {
	data, err := json.Marshal(action)
	if err != nil {
		return fmt.Errorf("failed to marshal action data: %w", err)
	}

	return db.actions.Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set("action:"+action.Reference, string(data), nil)
		if err != nil {
			return fmt.Errorf("failed to store action in cache: %w", err)
		}

		return nil
	})
}

// PopAction removes an action from the cache by its key.
func (db *Cache) PopAction(key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return db.actions.Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf("failed to remove action with key %s: %w", key, err)
		}

		return nil
	})
}

// GetAction retrieves a single action from the cache by its key.
func (db *Cache) GetAction(key string) (*models.Action, error) {
	if key == "" {
		return nil, fmt.Errorf("key cannot be empty")
	}

	var action models.Action

	err := db.actions.View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)
		if err != nil {
			return fmt.Errorf("action not found for key %s: %w", key, err)
		}

		if err := json.Unmarshal([]byte(val), &action); err != nil {
			return fmt.Errorf("failed to unmarshal action data: %w", err)
		}

		return nil
	})

	if err != nil {
		return nil, err
	}

	return &action, nil
}

// GetActions retrieves a paginated list of actions from the cache.
func (db *Cache) GetActions(skip, limit int) ([]models.Action, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	var actions []models.Action

	err := db.actions.View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			if count < skip {
				count++

				return true
			}

			if collected >= limit {
				return false
			}

			var action models.Action
			if err := json.Unmarshal([]byte(value), &action); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal action at key %s: %w", key, err)

				return false
			}

			actions = append(actions, action)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve actions: %w", err)
	}

	return actions, nil
}

// GetActionCount returns the total number of actions stored in the cache.
func (db *Cache) GetActionCount() (int, error) {
	var count int

	err := db.actions.View(func(tx *buntdb.Tx) error {
		tx.Ascend(defaultCacheName, func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count actions: %w", err)
	}

	return count, nil
}
