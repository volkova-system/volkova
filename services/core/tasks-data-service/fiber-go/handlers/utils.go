package handlers

import (
	"github.com/gofiber/fiber/v3"
)

// sendError sends a standardized error response.
func sendError(c fiber.Ctx, status int, message string, err error) error {
	return c.Status(status).JSON(fiber.Map{
		"status":  "error",
		"message": message,
		"error":   err.Error(),
	})
}

// computePageData calculates pagination metadata.
func computePageData(skip, limit, total int) (int, int) {
	pages := (total + limit - 1) / limit
	if pages == 0 {
		pages = 1
	}

	page := (skip / limit) + 1

	return pages, page
}
