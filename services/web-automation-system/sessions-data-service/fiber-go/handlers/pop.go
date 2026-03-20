package handlers

import (
	"github.com/gofiber/fiber/v3"

	"sessions-data-service/data"
	"sessions-data-service/engines"
)

// PopSessionHandler handles DELETE /service/data/sessions/pop/:reference endpoint.
// Removes a session from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the session reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopSessionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popSessionFromCache(c, cache)
	}
}

// popSessionFromCache processes the session removal request.
//
func popSessionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "session reference cannot be empty" })
	}

	session, err := engines.PopSession(cache, "session:"+reference)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "session cache error" })
	}

	return c.JSON(fiber.Map{ "session": session })
}
