package handlers

import (
	"actions-data-service/data"
	"actions-data-service/version"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"
)

func HealthHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		err := cache.DB().View(func(tx *buntdb.Tx) error {
			return nil
		})

		if err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"health": fiber.Map{
					"status":  "unhealthy",
					"issue":   "database connectivity failed",
					"service": version.Name,
                    "version": version.Version,
				},
			})
		}

		return c.JSON(fiber.Map{
			"health": fiber.Map{
				"status":  "healthy",
				"service": version.Name,
                "version": version.Version,
			},
		})
	}
}
