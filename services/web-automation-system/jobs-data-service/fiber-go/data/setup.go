package data

import "github.com/tidwall/buntdb"

// SetupCache initialises a Cache from an existing BuntDB connection.
// It creates the required indexes and wraps the connection with the
// given name and persistence path.
//
// Use Open or OpenWithPath for the standard initialisation flow.
// Use SetupCache only when the caller manages the BuntDB connection
// directly (e.g. in tests).
func SetupCache(name string, db *buntdb.DB, path string) (*Cache, error) {
	if err := SetupIndexes(db); err != nil {
		return nil, err
	}

	return &Cache{name: name, jobs: db, path: path}, nil
}
