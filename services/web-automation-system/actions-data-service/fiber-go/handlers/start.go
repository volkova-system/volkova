package handlers

import (
	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

func StartHandler(onStart func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":   "initiated",

				"procedure": "start",

				"service":  settings.Name,
                "version":  settings.Version,
			},
		}); err != nil {
			return err
		}

		go onStart()

		return nil
	}
}
