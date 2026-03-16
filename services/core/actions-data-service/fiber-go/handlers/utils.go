package handlers

import (
	"log"

	"github.com/gofiber/fiber/v3"
)

// sendError returns standardized error response with logging.
func sendError(c fiber.Ctx, status int, message string, err error) error {
	log.Printf("ERROR [%d] %s: %v", status, message, err)

	return c.Status(status).JSON(fiber.Map{
		"error":   message,
		"details": err.Error(),
	})
}

// sendSuccess returns standardized success response.
func sendSuccess(c fiber.Ctx, message string) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": message,
	})
}

func computePageData(skip, limit, total int) (int, int) {
	if limit <= 0 {
		limit = 1
	}

	pages := 1
	if total > limit {
		pages = (total + limit - 1) / limit
	}

	page := (skip / limit) + 1

	return pages, page
}
