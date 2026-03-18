package handlers

import (
	"github.com/gofiber/fiber/v3"

	"queues-data-service/data"
	"queues-data-service/engines"
)

// GetQueueHandler handles GET /service/data/queues/:reference endpoint.
// Retrieves a single queue from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the queue reference
// Response: JSON queue data or error details
//
// Fails fast on missing reference or cache retrieval error.
//
func GetQueueHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getQueueFromCache(c, cache)
	}
}

// getQueueFromCache processes the single queue retrieval request.
//
func getQueueFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	queue, err := engines.GetQueue(cache, "queue:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusNotFound,
			"queue not found", err)
	}

	return sendQueueResponse(c, queue)
}

// sendQueueResponse returns single queue as JSON response.
//
func sendQueueResponse(c fiber.Ctx, queue interface{}) error {
	return c.JSON(fiber.Map{
		"status": "success",
		"queue":  queue,
	})
}
