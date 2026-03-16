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
	name        string
	actions     *buntdb.DB
	persistPath string
}

// Open creates and initializes a new in-memory cache instance.
func Open() (*Cache, error) {
	return OpenWithPath(os.Getenv("ACTIONS_CACHE_PATH"))
}

func OpenWithPath(dbPath string) (*Cache, error) {
	persistPath := ""
	if dbPath != "" && dbPath != ":memory:" {
		persistPath = dbPath
		if err := os.MkdirAll(filepath.Dir(persistPath),
            0755); err != nil {
			return nil, fmt.Errorf(
                "failed to create directory for db: %w", err)
		}
	}

	conn, err := buntdb.Open(":memory:")
	if err != nil {
		return nil, err
	}

	if persistPath != "" {
		if _, err := os.Stat(persistPath); err == nil {
			f, err := os.Open(persistPath)
			if err != nil {
				return nil, fmt.Errorf(
                    "failed to open db file for load: %w", err)
			}
			defer f.Close()
			if err := conn.Load(f); err != nil {
				return nil, fmt.Errorf(
                    "failed to load db snapshot: %w", err)
			}
		}
	}

	if err := conn.CreateIndex(
		defaultCacheName,
		"action:*",
		buntdb.IndexString,
	); err != nil {
		return nil, err
	}

	if err := conn.CreateIndex(
		"reference",
		"action:*",
		func(a, b string) bool {
			var actionA, actionB models.Action

			json.Unmarshal([]byte(a), &actionA)
			json.Unmarshal([]byte(b), &actionB)

			return actionA.Reference < actionB.Reference
		},
	); err != nil {
		return nil, err
	}

	return &Cache{name: defaultCacheName, actions: conn,
        persistPath: persistPath}, nil
}

// DB returns the underlying BuntDB instance.
func (db *Cache) DB() *buntdb.DB {
	return db.actions
}

// Close gracefully shuts down the cache and releases all resources.
func (db *Cache) Close() error {
	if db.persistPath != "" {
		if err := os.MkdirAll(filepath.Dir(db.persistPath),
            0755); err != nil {
			return fmt.Errorf(
                "failed to create directory for db: %w", err)
		}

		f, err := os.Create(db.persistPath)
		if err != nil {
			return fmt.Errorf(
                "failed to create db file: %w", err)
		}
		defer f.Close()

		if err := db.actions.Save(f); err != nil {
			return fmt.Errorf(
                "failed to save db snapshot: %w", err)
		}
	}

	return db.actions.Close()
}
