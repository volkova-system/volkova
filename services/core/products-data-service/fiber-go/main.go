package main

import (
	"log"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"

	"products-data-service/cache"
	"products-data-service/handlers"
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
    data := service.Group("/data")
	products := data.Group("/products")

	products.Get("/health", func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	})

	products.Get("/", handlers.GetProductsHandler(cache))
    products.Get("/search", handlers.SearchProductHandler(cache))
    products.Get("/sort", handlers.SortProductHandler(cache))
    products.Get("/sort/criteria", handlers.GetSortCriteriaProductHandler(cache))
    products.Get("/filter", handlers.FilterProductHandler(cache))
    products.Get("/filter/fields", handlers.GetFilterFieldsProductHandler(cache))

    products.Post("/push", handlers.PushProductHandler(cache))
	products.Delete("/pop/:reference", handlers.PopProductHandler(cache))

    products.Get("/:reference", handlers.GetProductHandler(cache))

	server.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Not Found",
			"path":  c.Path(),
		})
	})

	log.Fatal(server.Listen(":4979"))
}
