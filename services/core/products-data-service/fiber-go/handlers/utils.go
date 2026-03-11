package handlers

import (
	"github.com/gofiber/fiber/v3"
)

// sendError returns standardized error response.
//
func sendError(c fiber.Ctx, status int, message string, err error) error {
	return c.Status(status).JSON(fiber.Map{
		"error":   message,
		"details": err.Error(),
	})
}
