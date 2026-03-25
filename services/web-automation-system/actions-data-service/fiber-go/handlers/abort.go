package handlers

import (
	"actions-data-service/version"

	"github.com/gofiber/fiber/v3"
)

func AbortHandler(onAbortAndShutdown func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":   "initiated",
				"procedure": "abort",
				"service":  version.Name,
				"version":  version.Version,
			},
		}); err != nil {
			return err
		}

		go onAbortAndShutdown()

		return nil
	}
}
