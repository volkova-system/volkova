// Package data provides an in-memory caching layer for action data using BuntDB.
// It offers efficient storage and retrieval of action information with indexing
// capabilities for optimized queries.
package data

import (
	"actions-data-service/settings"
	"fmt"
	"os"
	"path/filepath"

	"github.com/tidwall/buntdb"
)

// defaultCacheName is the default index name used for action storage.
const defaultCacheName = "actions"

// Cache represents an in-memory cache for action data using BuntDB.
type Cache struct {
	name    string
	actions *buntdb.DB
	path    string
}

func (db *Cache) DB() *buntdb.DB {
	return db.actions
}

func (db *Cache) Name() string {
	return db.name
}

func (db *Cache) Path() string {
	return db.path
}

// Open creates and initializes a new in-memory cache instance.
func Open() (*Cache, error) {
	dbPath := os.Getenv("ACTIONS_CACHE_PATH")

	if dbPath == "" {
		absPath, err := filepath.Abs("./data")
		if err != nil {
			return nil, fmt.Errorf("failed to get absolute path: %w", err)
		}

		dbPath = filepath.Join(absPath, "actions-cache.db")
	}

	return OpenWithPath(dbPath)
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

	if err := SetupIndexes(conn); err != nil {
		return nil, err
	}

	return &Cache{
		name:    settings.DefaultCacheName,
		actions: conn,
		path:    persistPath,
	}, nil
}

// Close gracefully shuts down the cache and releases all resources.
func (db *Cache) Close() error {
	if db.path != "" {
		if err := os.MkdirAll(filepath.Dir(db.path),
			0755); err != nil {
			return fmt.Errorf(
				"failed to create directory for db: %w", err)
		}

		f, err := os.Create(db.path)
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
