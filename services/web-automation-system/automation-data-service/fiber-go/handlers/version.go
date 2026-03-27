package handlers

import (
	"automation-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

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
