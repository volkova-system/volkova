// Package cache provides an in-memory caching layer for product data using BuntDB.
// It offers efficient storage and retrieval of product information with indexing
// capabilities for optimized queries.
package cache

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"

	"github.com/tidwall/buntdb"

	"products-data-service/model"
)

// defaultCacheName is the default index name used for product storage.
const defaultCacheName = "products"

// Cache represents an in-memory cache for product data using BuntDB.
// It provides thread-safe operations for storing and retrieving products
// with built-in indexing for efficient queries.
type Cache struct {
	name     string     // name of the cache index
	products *buntdb.DB // underlying BuntDB database connection
}

// Open creates and initializes a new in-memory cache instance.
// It sets up the BuntDB database with necessary indexes for efficient
// product querying by key, reference, and headline.
//
// Returns:
//   - *Cache:  A new cache instance ready for use
//   - error:   Any error that occurred during initialization
//
// The cache creates two indexes:
//   - "products":  General index for all product keys matching "product:*" pattern
//   - "reference": Custom index for reference-based lookups with string comparison
//
func Open() (*Cache, error) {
	if path := os.Getenv("PRODUCTS_CACHE_PATH"); path != "" {
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
		if err := os.MkdirAll(filepath.Dir(dbPath), 0755);
            err != nil {
			return nil, fmt.Errorf(
                "failed to create directory for db: %w", err)
		}

		conn, err = buntdb.Open(dbPath)
		if err != nil {
			return nil, err
		}
	}

	err = conn.CreateIndex(
        defaultCacheName,
        "product:*",
        buntdb.IndexString,
    )
	if err != nil {
		return nil, err
	}

	err = conn.CreateIndex(
        "reference",
        "product:*",
        func(a, b string) bool {
            var productA, productB model.Product
            json.Unmarshal([]byte(a), &productA)
            json.Unmarshal([]byte(b), &productB)
            return productA.Reference < productB.Reference
        },
    )
	if err != nil {
		return nil, err
	}

    err = conn.CreateIndex(
        "headline",
        "product:*",
        func(a, b string) bool {
            var productA, productB model.Product
            json.Unmarshal([]byte(a), &productA)
            json.Unmarshal([]byte(b), &productB)
            return productA.Headline < productB.Headline
        },
    )
	if err != nil {
		return nil, err
	}

	return &Cache{name: defaultCacheName, products: conn}, nil
}

// Close gracefully shuts down the cache and releases all resources.
// It closes the underlying BuntDB connection and should be called
// when the cache is no longer needed to prevent resource leaks.
//
// Returns:
//   - error:   Any error that occurred during the close operation
//
func (db *Cache) Close() error {
	return db.products.Close()
}

// PushProduct stores a product in the cache using its cache identifier as the key.
// The product is serialized to JSON and stored in a thread-safe transaction.
// If a product with the same cache identifier already exists, it will be
// overwritten. This operation invalidates cached metadata.
//
// Parameters:
//   - product: The product to store in the cache
//
// Returns:
//   - error:   Any error that occurred during marshaling or storage
//
func (db *Cache) PushProduct(product model.Product) error {
    // Marshal product to JSON with error context
    data, err := json.Marshal(product)
    if err != nil {
        return fmt.Errorf("failed to marshal product data: %w", err)
    }

    // Store in cache with transaction safety
    return db.products.Update(func(tx *buntdb.Tx) error {
        _, _, err := tx.Set(product.CacheIdentifier.Value,
            string(data), nil)
        if err != nil {
            return fmt.Errorf(
                "failed to store product in cache: %w", err)
        }

        // Invalidate cached metadata
        db.invalidateMetadataCache(tx)

        return nil
    })
}

// PopProduct removes a product from the cache by its key.
// The product is deleted from the cache in a thread-safe transaction.
// If the product doesn't exist, an error is returned. This operation
// invalidates cached metadata.
//
// Parameters:
//   - key: The cache key to remove
//          (typically the product's cache identifier value)
//
// Returns:
//   - error:   Any error that occurred during the removal operation
//
func (db *Cache) PopProduct(key string) error {
	if key == "" {
		return fmt.Errorf("key cannot be empty")
	}

	return db.products.Update(func(tx *buntdb.Tx) error {
		_, err := tx.Delete(key)
		if err != nil {
			return fmt.Errorf(
                "failed to remove product with key %s: %w", key, err)
		}

		// Invalidate cached metadata
		db.invalidateMetadataCache(tx)

		return nil
	})
}

// GetProduct retrieves a single product from the cache by its key.
// The product data is deserialized from JSON and returned as a Product struct.
//
// Parameters:
//   - key: The cache key to look up
//          (typically the product's cache identifier value)
//
// Returns:
//   - *model.Product:  The retrieved product, or nil if not found or error
//                      occurred
//
//   - error:           Any error that occurred during retrieval or unmarshaling
//
// Returns an error if:
//   - The key is empty
//   - The product is not found in the cache
//   - JSON unmarshaling fails
//
func (db *Cache) GetProduct(key string) (*model.Product, error) {
	if key == "" {
        return nil, fmt.Errorf("key cannot be empty")
    }

    var product model.Product

	err := db.products.View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)

		if err != nil {
			return fmt.Errorf(
                "product not found for key %s: %w", key, err)
		}

        if err := json.Unmarshal([]byte(val), &product); err != nil {
            return fmt.Errorf(
                "failed to unmarshal product data: %w", err)
        }

        return nil
	})

	if err != nil {
		return nil, err
	}

	return &product, nil
}

// GetProducts retrieves a paginated list of products from the cache.
// Products are returned in ascending order based on the default cache index.
// Supports pagination through skip and limit parameters.
//
// Parameters:
//   - skip:    Number of products to skip (offset). Negative values are treated as 0
//
//   - limit:   Maximum number of products to return. Values <= 0 default to 10
//
// Returns:
//   - []model.Product: Slice of products matching the pagination criteria
//
//   - error:           Any error that occurred during retrieval or unmarshaling
//
// The function uses the BuntDB Ascend method to iterate through products
// in index order, applying skip/limit logic for pagination.
//
func (db *Cache) GetProducts(skip, limit int) ([]model.Product, error) {
	if skip < 0 {
		skip = 0
	}

    if limit <= 0 {
		limit = 10
	}

	var products []model.Product

	err := db.products.View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			// Skip items until we reach the skip offset
			if count < skip {
				count++

				return true
			}

			// Stop if we've collected enough items
			if collected >= limit {
				return false
			}

			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
                    "failed to unmarshal product at key %s: %w",
                    key, err)

                return false
			}

			products = append(products, product)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve products: %w", err)
	}

	return products, nil
}

// GetProductCount returns the total number of products stored in the cache.
// This is useful for pagination calculations and providing total count metadata.
//
// Returns:
//   - int:     The total number of products in the cache
//
//   - error:   Any error that occurred during the count operation
//
func (db *Cache) GetProductCount() (int, error) {
	var count int

	err := db.products.View(func(tx *buntdb.Tx) error {
		tx.Ascend(defaultCacheName, func(key, value string) bool {
			count++

			return true
		})

		return nil
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count products: %w", err)
	}

	return count, nil
}

// GetSearchCount returns the total number of products matching a search query.
// This is useful for pagination calculations when searching products by headline.
//
// Parameters:
//   - query: Regex pattern to match against product headlines.
//            Empty string counts all products
//
// Returns:
//   - int:     The total number of products matching the search criteria
//
//   - error:   Any error that occurred during the count operation or
//              regex compilation
//
func (db *Cache) GetSearchCount(query string) (int, error) {
	// Compile regex pattern if search value is provided
	var searchRegex *regexp.Regexp
	var err error
	if query != "" {
		// Case-insensitive search
		searchRegex, err = regexp.Compile("(?i)" + query)
		if err != nil {
			return 0, fmt.Errorf(
				"invalid regex pattern '%s': %w", query, err)
		}
	}

	var count int

	err = db.products.View(func(tx *buntdb.Tx) error {
		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal product at key %s: %w",
					key, err)
				return false
			}

			// If search value is provided, check if headline matches the regex
			if searchRegex != nil && !searchRegex.MatchString(product.Headline) {
				return true // Continue to next product without counting
			}

			count++
			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return 0, fmt.Errorf("failed to count search results: %w", err)
	}

	return count, nil
}

// SearchProducts searches for products by headline using regex pattern matching.
// Products are returned in ascending order based on the default cache index.
// Supports pagination through skip and limit parameters.
//
// Parameters:
//   - query:   Regex pattern to match against product headlines.
//              Empty string returns all products
//
//   - skip:    Number of matching products to skip (offset).
//              Negative values are treated as 0
//
//   - limit:   Maximum number of products to return. Values <= 0 default to 10
//
// Returns:
//   - []model.Product: Slice of products with headlines
//                      matching the search pattern
//
//   - error:           Any error that occurred during retrieval,
//                      regex compilation, or unmarshaling
//
// The function compiles the search value as a regex pattern and matches it against
// each product's headline field. If query is empty, all products are returned.
//
func (db *Cache) SearchProducts(query string,
    skip, limit int) ([]model.Product, error) {
	if skip < 0 {
		skip = 0
	}

	if limit <= 0 {
		limit = 10
	}

	// Compile regex pattern if search value is provided
	var searchRegex *regexp.Regexp
	var err error
	if query != "" {
        // Case-insensitive search
		searchRegex, err = regexp.Compile("(?i)" + query)
		if err != nil {
			return nil, fmt.Errorf(
                "invalid regex pattern '%s': %w", query, err)
		}
	}

	var products []model.Product

	err = db.products.View(func(tx *buntdb.Tx) error {
		count := 0
		collected := 0

		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal product at key %s: %w",
					key, err)

				return false
			}

			// If search value is provided, check if headline matches the regex
			if searchRegex != nil && !searchRegex.MatchString(product.Headline) {
                // Continue to next product without incrementing counters
				return true
			}

			// Skip items until we reach the skip offset
			if count < skip {
				count++
				return true
			}

			// Stop if we've collected enough items
			if collected >= limit {
				return false
			}

			products = append(products, product)

			collected++
			count++

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to search products: %w", err)
	}

	return products, nil
}

// GetSortCriteria returns all unique values of the sortCriteria field
// from all products stored in the cache. This is useful for providing
// available sorting options to clients. Results are cached for performance.
//
// Returns:
//   - []string:    Slice of unique sortCriteria values found in all products
//
//   - error:       Any error that occurred during retrieval or unmarshaling
//
func (db *Cache) GetSortCriteria() ([]string, error) {
	const cacheKey = "products:sortCriteria"

	// Try to get cached result first
	var cachedCriteria []string
	err := db.products.View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(cacheKey)
		if err == nil {
			// Cache hit - unmarshal and return
			return json.Unmarshal([]byte(val), &cachedCriteria)
		}
		return err
	})

	// If cache hit and no unmarshal error, return cached result
	if err == nil {
		return cachedCriteria, nil
	}

	// Cache miss - compute the result
	criteriaMap := make(map[string]bool)

	err = db.products.View(func(tx *buntdb.Tx) error {
		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			// Skip the cache key itself
			if key == cacheKey {
				return true
			}

			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal product at key %s: %w", key, err)

				return false
			}

			// Add each sortCriteria to map if slice is not empty
			for _, criterion := range product.SortCriteria {
				if criterion != "" {
					criteriaMap[criterion] = true
				}
			}

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve sort criteria: %w", err)
	}

	// Convert map keys to slice
	criteria := make([]string, 0, len(criteriaMap))
	for criterion := range criteriaMap {
		criteria = append(criteria, criterion)
	}

	// Cache the result
	err = db.products.Update(func(tx *buntdb.Tx) error {
		data, err := json.Marshal(criteria)
		if err != nil {
			return fmt.Errorf("failed to marshal sort criteria: %w", err)
		}

		_, _, err = tx.Set(cacheKey, string(data), nil)
		if err != nil {
			return fmt.Errorf("failed to cache sort criteria: %w", err)
		}

		return nil
	})

	if err != nil {
		// Log the caching error but don't fail the request
		// Return the computed result anyway
		return criteria, nil
	}

	return criteria, nil
}

// GetFilterFields returns all unique values of the filterFields field
// from all products stored in the cache. This is useful for providing
// available filtering options to clients.
//
// Returns:
//   - []string: Slice of unique filterFields values found in all products
//
//   - error:    Any error that occurred during retrieval or unmarshaling
//
func (db *Cache) GetFilterFields() ([]string, error) {
	fieldsMap := make(map[string]bool)

	err := db.products.View(func(tx *buntdb.Tx) error {
		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal product at key %s: %w", key, err)

				return false
			}

			// Add each filterField to map if slice is not empty
			for _, field := range product.FilterFields {
				if field != "" {
					fieldsMap[field] = true
				}
			}

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve filter fields: %w", err)
	}

	// Convert map keys to slice
	fields := make([]string, 0, len(fieldsMap))
	for field := range fieldsMap {
		fields = append(fields, field)
	}

	return fields, nil
}

// GetFilterFieldValues returns all unique values for each filter field
// from all products stored in the cache. This is useful for providing
// available filter options with their possible values to clients.
// Filter fields can be either first-level Product fields or in AdditionalProperty.
//
// Returns:
//   - map[string][]string: Map where keys are filter field names and values are
//                          slices of unique values for each field
//
//   - error:               Any error that occurred during retrieval or
//                          unmarshaling
//
func (db *Cache) GetFilterFieldValues() (map[string][]string, error) {
	// Get unique filter fields first
	filterFields, err := db.GetFilterFields()
	if err != nil {
		return nil, fmt.Errorf("failed to get filter fields: %w", err)
	}

	// Create a map to store field values
	fieldValuesMap := make(map[string]map[string]bool)
	for _, field := range filterFields {
		fieldValuesMap[field] = make(map[string]bool)
	}

	err = db.products.View(func(tx *buntdb.Tx) error {
		var unmarshalErr error

		tx.Ascend(defaultCacheName, func(key, value string) bool {
			var product model.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				unmarshalErr = fmt.Errorf(
					"failed to unmarshal product at key %s: %w", key, err)

				return false
			}

			// Extract values for each filter field
			for _, fieldName := range filterFields {
				if valuesMap, exists := fieldValuesMap[fieldName]; exists {
					// Check first-level Product fields explicitly
					switch fieldName {
					case "brandName":
						if product.BrandName != "" {
							valuesMap[product.BrandName] = true
						}

					case "keywords":
						for _, keyword := range product.Keywords {
							if keyword != "" {
								valuesMap[keyword] = true
							}
						}

					default:
						// Check AdditionalProperty for custom fields
						for _, prop := range product.AdditionalProperty {
							if prop.Name == fieldName && prop.Value != "" {
								valuesMap[prop.Value] = true
							}
						}
					}
				}
			}

			return true
		})

		return unmarshalErr
	})

	if err != nil {
		return nil, fmt.Errorf("failed to retrieve filter field values: %w", err)
	}

	// Convert maps to slices
	result := make(map[string][]string)
	for fieldName, valuesMap := range fieldValuesMap {
		values := make([]string, 0, len(valuesMap))
		for value := range valuesMap {
			values = append(values, value)
		}

		result[fieldName] = values
	}

	return result, nil
}

// invalidateMetadataCache removes cached metadata that becomes stale
// when products are added or removed from the cache.
func (db *Cache) invalidateMetadataCache(tx *buntdb.Tx) {
	// Remove cached sort criteria
	tx.Delete("products:sortCriteria")
	// Remove cached filter fields (when we add caching for it)
	tx.Delete("products:filterFields")
	// Remove cached filter field values (when we add caching for it)
	tx.Delete("products:filterFieldValues")
}
