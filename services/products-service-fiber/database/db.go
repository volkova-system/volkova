package database

import (
	"encoding/json"
	"fmt"
	"log"

	"github.com/tidwall/buntdb"
	"product-service/models"
)

type DB struct {
	conn *buntdb.DB
}

// NewDB creates a new in-memory BuntDB instance
func NewDB() (*DB, error) {
	db, err := buntdb.Open(":memory:")
	if err != nil {
		return nil, fmt.Errorf("failed to open BuntDB: %w", err)
	}

	// Create indexes for efficient querying
	err = db.CreateIndex("products", "product:*", buntdb.IndexString)
	if err != nil {
		return nil, fmt.Errorf("failed to create products index: %w", err)
	}

	// Index by SKU for unique lookups
	err = db.CreateIndex("sku", "product:*", func(a, b string) bool {
		var productA, productB models.Product
		json.Unmarshal([]byte(a), &productA)
		json.Unmarshal([]byte(b), &productB)
		return productA.SKU < productB.SKU
	})
	if err != nil {
		return nil, fmt.Errorf("failed to create SKU index: %w", err)
	}

	return &DB{conn: db}, nil
}

// Close closes the database connection
func (d *DB) Close() error {
	return d.conn.Close()
}

// SaveProduct stores a product in BuntDB
func (d *DB) SaveProduct(product *models.Product) error {
	data, err := json.Marshal(product)
	if err != nil {
		return fmt.Errorf("failed to marshal product: %w", err)
	}

	return d.conn.Update(func(tx *buntdb.Tx) error {
		key := fmt.Sprintf("product:%s", product.ID)
		_, _, err := tx.Set(key, string(data), nil)
		return err
	})
}

// GetProduct retrieves a product by ID
func (d *DB) GetProduct(id string) (*models.Product, error) {
	var product models.Product

	err := d.conn.View(func(tx *buntdb.Tx) error {
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

// GetAllProducts retrieves all products
func (d *DB) GetAllProducts() ([]models.Product, error) {
	var products []models.Product

	err := d.conn.View(func(tx *buntdb.Tx) error {
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

// DeleteProduct removes a product by ID
func (d *DB) DeleteProduct(id string) error {
	return d.conn.Update(func(tx *buntdb.Tx) error {
		key := fmt.Sprintf("product:%s", id)
		_, err := tx.Delete(key)
		return err
	})
}
