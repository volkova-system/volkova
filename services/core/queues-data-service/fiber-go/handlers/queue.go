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
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "queue reference cannot be empty" })
	}

	queue, err := engines.GetQueue(cache, "queue:"+reference)
	if err != nil {
		return c.Status(fiber.StatusNotFound).JSON(
			fiber.Map{ "error": "queue not found" })
	}

	return c.JSON(fiber.Map{ "queue": queue })
}
