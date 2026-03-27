package handlers

import (
	"errors"

	"github.com/gofiber/fiber/v3"
	"github.com/tidwall/buntdb"

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
func PopActionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popActionFromCache(c, cache)
	}
}

// popActionFromCache processes the action removal request.
func popActionFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return IssueResponse(c, fiber.StatusBadRequest, "action reference cannot be empty")
	}

	action, err := engines.PopAction(cache, "action:"+reference)
	if err != nil {
		if errors.Is(err, buntdb.ErrNotFound) {
			return IssueResponse(c, fiber.StatusNotFound, "action not found")
		}

		return IssueResponse(c, fiber.StatusInternalServerError, "action cache error")
	}

	return c.JSON(fiber.Map{"action": action})
}
