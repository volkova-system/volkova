package handlers

import (
	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// VersionHandler handles GET /service/data/actions/version endpoint.
// Returns the current service version and service name.
//
// Response: JSON version object with number and service fields.
func VersionHandler() fiber.Handler {
	return func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"version": fiber.Map{
				"number":  settings.Version,
				"service": settings.DataServiceName,
			},
		})
	}
}
