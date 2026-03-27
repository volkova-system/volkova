package handlers

import (
	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

func AbortHandler(onAbort func()) fiber.Handler {
	return func(c fiber.Ctx) error {
		if err := c.JSON(fiber.Map{
			"operation": fiber.Map{
				"status":    "initiated",
				"procedure": "abort",
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		}); err != nil {
			return err
		}

		go onAbort()

		return nil
	}
}
