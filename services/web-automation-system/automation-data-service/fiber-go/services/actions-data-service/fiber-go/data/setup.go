package data

import "github.com/tidwall/buntdb"

func SetupCache(name string, db *buntdb.DB, path string) (*Cache, error) {
	if err := SetupIndexes(db); err != nil {
		return nil, err
	}

	return &Cache{name: name, actions: db, path: path}, nil
}
