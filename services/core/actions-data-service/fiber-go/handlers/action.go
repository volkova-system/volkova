package handlers

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/data"
	"actions-data-service/engines"
)

// GetActionHandler handles GET /service/data/actions/:reference endpoint.
// Retrieves a single action from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the action reference
// Response: JSON action data or error details
//
// Fails fast on missing reference or cache retrieval error.
//
func GetActionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getActionFromCache(c, cache)
	}
}

// getActionFromCache processes the single action retrieval request.
//
func getActionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
        return c.Status(fiber.StatusBadRequest).JSON(
            fiber.Map{ "error": "action reference cannot be empty" })
	}

	action, err := engines.GetAction(cache, "action:"+reference)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(
            fiber.Map{ "error": "action not found" })
	}

	return c.JSON(fiber.Map{ "action": action })
}
