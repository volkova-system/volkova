package handlers

import (
	"fmt"

	"github.com/gofiber/fiber/v3"

	"queues-data-service/data"
	"queues-data-service/engines"
	"queues-data-service/models"
)

// PushQueueHandler handles POST /service/data/queues/push endpoint.
// Accepts JSON queue document and stores it in cache using reference as the key.
//
// Request: JSON queue document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
//
func PushQueueHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushQueueToCache(c, cache)
	}
}

// pushQueueToCache processes the queue push request.
//
func pushQueueToCache(c fiber.Ctx, cache *data.Cache) error {
	queue, err := parseQueueFromRequest(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest, "invalid queue data", err)
	}

	err = validateQueueData(queue)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest, "validation failed", err)
	}

	err = storeQueueInCache(cache, queue)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError, "cache error", err)
	}

	return sendSuccess(c, "queue pushed successfully")
}

// parseQueueFromRequest extracts queue data from request body.
//
func parseQueueFromRequest(c fiber.Ctx) (*models.Queue, error) {
	var queue models.Queue

	err := c.Bind().JSON(&queue)
	if err != nil {
		return nil, err
	}

	return &queue, nil
}

// validateQueueData ensures required fields are present and within limits.
//
func validateQueueData(queue *models.Queue) error {
	if queue.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest, "reference required")
	}

	if queue.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest, "name required")
	}

    // Validate tasks
	for t, task := range queue.Job.Tasks {
		if task.Reference == "" {
			return fiber.NewError(fiber.StatusBadRequest,
                fmt.Sprintf("task reference required at index %d", t))
		}
		if task.Name == "" {
			return fiber.NewError(fiber.StatusBadRequest,
                fmt.Sprintf("task name required at index %d", t))
		}

		// Validate actions within tasks
		for a, action := range task.Actions {
			if action.Reference == "" {
				return fiber.NewError(fiber.StatusBadRequest,
                    fmt.Sprintf("action reference required at task %d, action %d",
                        t, a))
			}
			if action.Name == "" {
				return fiber.NewError(fiber.StatusBadRequest,
                    fmt.Sprintf("action name required at task %d, action %d",
                        t, a))
			}
		}
	}

	return nil
}

// storeQueueInCache saves queue to cache storage.
//
func storeQueueInCache(cache *data.Cache, queue *models.Queue) error {
	return engines.PushQueue(cache, *queue)
}
