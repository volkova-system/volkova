package main

import (
	"log"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"

	"products-data-service/data"
	"products-data-service/handlers"
)

func main() {
	cache, err := data.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName: "core-product-data-service",
		ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("Fiber error [%d]: %v", code, err)

			return c.Status(code).JSON(fiber.Map{
				"error": err.Error(),
			})
		},
	})

	// Add recovery middleware to catch panics
	server.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))
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
