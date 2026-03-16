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

// DB returns the underlying BuntDB instance.
func (db *Cache) DB() *buntdb.DB {
	return db.actions
}

// Close gracefully shuts down the cache and releases all resources.
func (db *Cache) Close() error {
	return db.actions.Close()
}
