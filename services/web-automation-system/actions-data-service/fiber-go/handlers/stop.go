package handlers

import (
	"actions-data-service/version"

	"github.com/gofiber/fiber/v3"
)

func StopHandler(onStop func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "shutdown",
				"service":   version.Name,
			},
		}); err != nil {
			return err
		}

		go onStop()

		return nil
	}
}
