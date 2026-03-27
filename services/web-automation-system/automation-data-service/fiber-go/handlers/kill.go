package handlers

import (
	"automation-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

func KillHandler(onKill func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "kill",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onKill()

		return nil
	}
}
