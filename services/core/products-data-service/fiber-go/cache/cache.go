// Package cache provides an in-memory caching layer for product data using BuntDB.
// It offers efficient storage and retrieval of product information with indexing
// capabilities for optimized queries.
package cache

import (
	"encoding/json"
	"fmt"
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
// product querying by key and SKU.
//
// Returns:
//   - *Cache:  A new cache instance ready for use
//   - error:   Any error that occurred during initialization
//
// The cache creates two indexes:
//   - "products":  General index for all product keys matching "product:*" pattern
//   - "sku":       Custom index for SKU-based lookups with string comparison
func Open() (*Cache, error) {
	conn, err := buntdb.Open(":memory:")

	if err != nil {
		return nil, err
	}

	// Create indexes for efficient querying
	err = conn.CreateIndex(
        defaultCacheName,
        "product:*",
        buntdb.IndexString,
    )

	if err != nil {
		return nil, err
	}

	// Index by SKU for unique lookups
	err = conn.CreateIndex(
        "sku",
        "product:*",
        func(a, b string) bool {
            var productA, productB model.Product
            json.Unmarshal([]byte(a), &productA)
            json.Unmarshal([]byte(b), &productB)
            return productA.SKU < productB.SKU
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
// overwritten.
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

        return nil
    })
}

// PopProduct removes a product from the cache by its key.
// The product is deleted from the cache in a thread-safe transaction.
// If the product doesn't exist, an error is returned.
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
