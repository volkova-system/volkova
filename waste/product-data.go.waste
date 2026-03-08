package database

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/tidwall/buntdb"

	"product-data-service/models"
)

const defaultDBName = "products"

type DB struct {
    name     string
	products *buntdb.DB
}

func NewDB() (*DB, error) {
	conn, err := buntdb.Open(":memory:")

	if err != nil {
		return nil, fmt.Errorf("failed to open BuntDB: %w", err)
	}

	// Create indexes for efficient querying
	err = conn.CreateIndex(
        defaultDBName,
        "product:*",
        buntdb.IndexString,
    )

	if err != nil {
		return nil, fmt.Errorf("failed to create products index: %w", err)
	}

	// Index by SKU for unique lookups
	err = conn.CreateIndex(
        "sku",
        "product:*",
        func(a, b string) bool {
            var productA, productB models.Product
            json.Unmarshal([]byte(a), &productA)
            json.Unmarshal([]byte(b), &productB)
            return productA.SKU < productB.SKU
        },
    )

	if err != nil {
		return nil, fmt.Errorf("failed to create SKU index: %w", err)
	}

	return &DB{name: defaultDBName, products: conn}, nil
}

func (db *DB) Close() error {
	return db.products.Close()
}

func (db *DB) PushProduct(product models.Product) error {


    data, err := json.Marshal(product)
	if err != nil {
		return err
	}

    return db.products.Update(func(tx *buntdb.Tx) error {
		_, _, err := tx.Set(product.Key, string(data), nil)
		return err
	})
}

func (db *DB) GetProduct(id string) (*models.Product, error) {
	var product models.Product

	err := db.products.View(func(tx *buntdb.Tx) error {
		key := fmt.Sprintf("product:%s", id)
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

func (db *DB) GetProducts() ([]models.Product, error) {
	var products []models.Product

	err := db.products.View(func(tx *buntdb.Tx) error {
		return tx.Ascend("products", func(key, value string) bool {
			var product models.Product
			if err := json.Unmarshal([]byte(value), &product); err != nil {
				log.Printf("Error unmarshaling product %s: %v", key, err)
				return true // continue iteration
			}
			products = append(products, product)
			return true // continue iteration
		})
	})

	return products, err
}


