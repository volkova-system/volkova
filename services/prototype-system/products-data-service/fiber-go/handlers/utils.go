package handlers

import (
	"log"

	"github.com/gofiber/fiber/v3"
)

// sendError returns standardized error response with logging.
//
func sendError(c fiber.Ctx, status int, message string, err error) error {
	// Log the error for debugging
	log.Printf("ERROR [%d] %s: %v", status, message, err)

	return c.Status(status).JSON(fiber.Map{
		"error":   message,
		"details": err.Error(),
	})
}

func computePageData(skip, limit, total int) (int, int) {
    // Prevent division by zero
    if limit <= 0 {
        limit = 1
    }

    pages := 1
    if total > limit {
        pages = (total + limit - 1) / limit // Ceiling division
    }

    page := (skip / limit) + 1

    return pages, page
}
