package handlers

import (
	"sessions-data-service/data"
	"sessions-data-service/settings"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"
)

// HealthDataHandler handles GET /service/data/sessions/health endpoint.
// Verifies database connectivity by opening a read-only transaction.
//
// Response: JSON health status with service name and version,
// or 503 if the database is unreachable.
func HealthDataHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		err := cache.DB().View(func(tx *buntdb.Tx) error {
			return nil
		})

		if err != nil {
			return IssueResponse(c, fiber.StatusServiceUnavailable, "database connectivity failed")
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

// HealthControlHandler handles GET /service/data/sessions/health endpoint
// on the control server.
// The control server has no database; it always returns healthy.
//
// Response: JSON health status with service name and version.
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
