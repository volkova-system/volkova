package main

import (
	"log"
	"time"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"

	"product-service/database"
	"product-service/handlers"
	"product-service/models"
)

func main() {
	// Initialize database
	db, err := database.NewDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	// Seed with sample data
	seedData(db)

	// Initialize Fiber app
	app := fiber.New(fiber.Config{
		AppName: "Product Service v1.0.0",
	})

	// Middleware
	app.Use(logger.New())
	app.Use(cors.New())

	// Initialize handlers
	productHandler := handlers.NewProductHandler(db)

	// Routes
	api := app.Group("/service")
	products := api.Group("/products")

	products.Get("/", productHandler.GetProducts)
	products.Get("/:id", productHandler.GetProduct)
	products.Post("/", productHandler.CreateProduct)
	products.Put("/:id", productHandler.UpdateProduct)
	products.Delete("/:id", productHandler.DeleteProduct)

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"service": "product-service",
		})
	})

	log.Println("Server starting on :3000")
	log.Fatal(app.Listen(":3000"))
}

// seedData adds sample product data to the database
func seedData(db *database.DB) {
	sampleProduct := &models.Product{
		Context:            "https://schema.org",
		Type:               "Product",
		ID:                 "product_unique_name",
		SKU:                "product_reference",
		Name:               "product_name",
		Headline:           "product_title",
		Description:        "product_description",
		URL:                "https://example.com/products/product_unique_name",
		Price:              80,
		RatingValue:        4.5,
		DiscountPercentage: 20,
		Brand: models.Brand{
			Type: "Brand",
			Name: "Brand Name",
		},
		Keywords: []string{"tag1", "tag2", "tag3"},
		Image:    []string{"thumbnail_uri", "picture_uri_1", "picture_uri_2"},
		DateCreated:  time.Now(),
		DateModified: time.Now(),
		AggregateRating: models.AggregateRating{
			Type:        "AggregateRating",
			RatingValue: 4.5,
			BestRating:  5,
			WorstRating: 1,
		},
		Offers: models.Offer{
			Type:          "Offer",
			PriceCurrency: "USD",
			Price:         80.00,
			Availability:  "https://schema.org/InStock",
			PriceSpecification: models.PriceSpecification{
				Type:          "PriceSpecification",
				Price:         100.00,
				PriceCurrency: "USD",
			},
			DiscountPercentage: 20,
		},
		AdditionalProperty: []models.PropertyValue{
			{
				Type:        "PropertyValue",
				Name:        "detail_name",
				Description: "detail_title",
				Value:       "detail_value",
			},
		},
	}

	if err := db.SaveProduct(sampleProduct); err != nil {
		log.Printf("Failed to seed sample data: %v", err)
	} else {
		log.Println("Sample product data seeded successfully")
	}
}
