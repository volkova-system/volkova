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

	service := fiber.New(fiber.Config{
		AppName: "sarikanto-product-data-service",
	})

	service.Use(logger.New())
	service.Use(cors.New())

	api := app.Group("/service")
	products := api.Group("/products")

	products.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	log.Fatal(app.Listen(":3000"))
}
