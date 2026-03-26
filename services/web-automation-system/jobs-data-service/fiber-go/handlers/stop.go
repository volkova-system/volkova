package handlers

import (
	"jobs-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

func StopHandler(onStop func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "shutdown",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onStop()

		return nil
	}
}
