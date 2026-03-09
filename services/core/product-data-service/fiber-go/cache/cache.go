package cache

import (
	"encoding/json"
	"fmt"

	"github.com/tidwall/buntdb"

	"product-data-service/model"
)

const defaultCacheName = "products"

type Cache struct {
    name     string
	products *buntdb.DB
}

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

func (db *Cache) Close() error {
	return db.products.Close()
}

func (db *Cache) PushProduct(product model.Product) error {
    // Marshal product to JSON with error context
    data, err := json.Marshal(product)
    if err != nil {
        return fmt.Errorf("failed to marshal product data: %w", err)
    }

    // Store in cache with transaction safety
    return db.products.Update(func(tx *buntdb.Tx) error {
        _, _, err := tx.Set(product.CacheIdentifier.Value, string(data), nil)
        if err != nil {
            return fmt.Errorf("failed to store product in cache: %w", err)
        }
        return nil
    })
}

func (db *Cache) GetProduct(key string) (*model.Product, error) {
	var product model.Product

	err := db.products.View(func(tx *buntdb.Tx) error {
		val, err := tx.Get(key)

		if err != nil {
			return err
		}

        return json.Unmarshal([]byte(val), &product)
	})

	if err != nil {
		return nil, err
	}

	return &product, nil
}
