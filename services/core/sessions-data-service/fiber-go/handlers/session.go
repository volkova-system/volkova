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
//
func GetSessionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getSessionFromCache(c, cache)
	}
}

// getSessionFromCache processes the single session retrieval request.
//
func getSessionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	session, err := engines.GetSession(cache, "session:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusNotFound,
			"session not found", err)
	}

	return sendSessionResponse(c, session)
}

// sendSessionResponse returns single session as JSON response.
//
func sendSessionResponse(c fiber.Ctx, session interface{}) error {
	return c.JSON(fiber.Map{
		"status": "success",
		"session": session,
	})
}
