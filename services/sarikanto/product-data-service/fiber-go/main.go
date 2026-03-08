package main

import (
	"log"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"

	"product-data-service/cache"
)

func main() {
	// Initialize cache
	cache, err := cache.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	app := fiber.New(fiber.Config{
		AppName: "sarikanto-product-data-service",
	})

	app.Use(logger.New())
	app.Use(cors.New())

	api := app.Group("/service")
	products := api.Group("/products")

	// Health check
	products.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	log.Println("Server starting on :3000")
	log.Fatal(app.Listen(":3000"))
}
