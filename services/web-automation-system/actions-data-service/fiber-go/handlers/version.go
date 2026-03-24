package handlers

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/version"
)

func VersionHandler() fiber.Handler {
	return func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"version": fiber.Map{
                "number": version.Version,
                "service": "actions-data-service",
            },
		})
	}
}
