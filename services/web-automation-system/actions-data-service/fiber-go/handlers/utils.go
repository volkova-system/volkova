package handlers

import (
	"actions-data-service/settings"

	"github.com/gofiber/fiber/v3"
)

// issueResponse creates a consistent issue response format for the API.
// It returns a standardized JSON issue structure with the given status code,
// description, and includes the request method and path for debugging.
func IssueResponse(c fiber.Ctx, statusCode int, description string) error {
	return c.Status(statusCode).JSON(fiber.Map{
		"issue": fiber.Map{
			"description": description,
			"method":      c.Method(),
			"path":        c.Path(),
		},

		"service": settings.DataServiceName,
		"version": settings.Version,
	})
}

// ComputePageData derives total page count and current page number
// from pagination parameters.
//
// Parameters:
//   - skip:  number of items skipped before the current page.
//   - limit: maximum items per page; clamped to 1 if zero or negative.
//   - total: total number of items in the collection.
//
// Returns pages (total page count) and page (1-based current page).
func ComputePageData(skip, limit, total int) (int, int) {
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
