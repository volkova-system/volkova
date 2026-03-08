package main

import (
	"log"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/cors"
	"github.com/gofiber/fiber/v2/middleware/logger"

	"product-data-service/database"
	"product-data-service/handlers"
)

func main() {
	// Initialize database
	db, err := database.NewDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

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

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
			"service": "product-data-service",
		})
	})

	log.Println("Server starting on :3000")
	log.Fatal(app.Listen(":3000"))
}
