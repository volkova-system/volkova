package handlers

import (
	"actions-data-service/version"

	"github.com/gofiber/fiber/v3"
)

func StartHandler(onStart func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":   "initiated",

				"procedure": "start",

				"service":  version.Name,
                "version":  version.Version,
			},
		}); err != nil {
			return err
		}

		go onStart()

		return nil
	}
}
