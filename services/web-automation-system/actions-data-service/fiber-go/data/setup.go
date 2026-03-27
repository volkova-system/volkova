package data

func SetupCache(cache *Cache) error {
	return SetupIndexes(cache.DB())
}
