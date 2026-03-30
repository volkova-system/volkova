package handlers

import (
	"github.com/gofiber/fiber/v3"

	"sessions-data-service/data"
	"sessions-data-service/engines"
)

// GetSessionHandler handles GET /service/data/sessions/:reference endpoint.
// Retrieves a single session from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the session reference
// Response: JSON session data or error details
//
// Fails fast on missing reference or cache retrieval error.
func GetSessionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getSessionFromCache(c, cache)
	}
}

// getSessionFromCache processes the single session retrieval request.
func getSessionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return IssueResponse(c, fiber.StatusBadRequest, "session reference cannot be empty")
	}

	session, err := engines.GetSession(cache, "session:"+reference)
	if err != nil {
		return IssueResponse(c, fiber.StatusNotFound, "session not found")
	}

	return c.JSON(fiber.Map{"session": session})
}
