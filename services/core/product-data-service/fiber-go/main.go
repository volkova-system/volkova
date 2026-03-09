package main

import (
	"log"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"

	"product-data-service/cache"
)

func main() {
	cache, err := cache.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName: "core-product-data-service",
	})

	server.Use(logger.New())
	server.Use(cors.New())

	service := server.Group("/service")
	products := service.Group("/products")

	products.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	log.Fatal(server.Listen(":4979"))
}
