package handlers

import (
	"github.com/gofiber/fiber/v3"
)

func StopHandler() fiber.Handler {
	return func(c fiber.Ctx) error {
		return c.JSON(fiber.Map{
			"status": "ok",
		})
	}
}
