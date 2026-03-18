package handlers

import (
	"github.com/gofiber/fiber/v3"

	"queues-data-service/data"
	"queues-data-service/engines"
)

// PopQueueHandler handles DELETE /service/data/queues/pop/:reference endpoint.
// Removes a queue from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the queue reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopQueueHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popQueueFromCache(c, cache)
	}
}

// popQueueFromCache processes the queue removal request.
//
func popQueueFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	err := engines.PopQueue(cache, "queue:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	return sendSuccess(c, "queue removed successfully")
}
