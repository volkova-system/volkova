package handlers

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/data"
	"actions-data-service/engines"
)

// PopActionHandler handles DELETE /service/data/actions/pop/:reference endpoint.
// Removes an action from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the action reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopActionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popActionFromCache(c, cache)
	}
}

// popActionFromCache processes the action removal request.
//
func popActionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	err := engines.PopAction(cache, "action:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	return sendSuccess(c, "action removed successfully")
}
