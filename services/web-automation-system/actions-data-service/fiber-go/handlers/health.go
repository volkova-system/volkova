package handlers

import (
	"actions-data-service/data"
	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"
)

func HealthDataHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		err := cache.DB().View(func(tx *buntdb.Tx) error {
			return nil
		})

		if err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"health": fiber.Map{
					"status": "unhealthy",
					"issue":  "database connectivity failed",
				},

				"service": settings.DataServiceName,
				"version": settings.Version,
			})
		}

		return c.JSON(fiber.Map{
			"health": fiber.Map{
				"status": "healthy",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		})
	}
}

func HealthControlHandler() fiber.Handler {
	return func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"health": fiber.Map{
				"status": "healthy",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		})
	}
}
