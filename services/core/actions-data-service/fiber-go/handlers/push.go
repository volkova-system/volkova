package handlers

import (
	"github.com/gofiber/fiber/v3"

	"actions-data-service/data"
	"actions-data-service/engines"
	"actions-data-service/models"
)

// PushActionHandler handles POST /service/data/actions/push endpoint.
// Accepts JSON action document and stores it in cache using reference as the key.
//
// Request: JSON action document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
//
func PushActionHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushActionToCache(c, cache)
	}
}

// pushActionToCache processes the action push request.
//
func pushActionToCache(c fiber.Ctx, cache *data.Cache) error {
	action, err := parseActionFromRequest(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "invalid action data", err)
	}

	err = validateActionData(action)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "validation failed", err)
	}

	err = storeActionInCache(cache, action)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache error", err)
	}

	return sendSuccess(c, "action pushed")
}

// parseActionFromRequest extracts action data from request body.
//
func parseActionFromRequest(c fiber.Ctx) (*models.Action, error) {
	var action models.Action

	err := c.Bind().JSON(&action)
	if err != nil {
		return nil, err
	}

	return &action, nil
}

// validateActionData ensures required fields are present and within limits.
//
func validateActionData(action *models.Action) error {
	if action.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reference required")
	}

	if action.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name required")
	}

	return nil
}

// storeActionInCache saves action to cache storage.
//
func storeActionInCache(cache *data.Cache, action *models.Action) error {
	return engines.PushAction(cache, *action)
}
