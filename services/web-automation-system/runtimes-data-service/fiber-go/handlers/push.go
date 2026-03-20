package handlers

import (
	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/data"
	"runtimes-data-service/engines"
	"runtimes-data-service/models"
)

// PushRuntimeHandler handles POST /service/data/runtimes/push endpoint.
// Accepts JSON runtime document and stores it in cache using reference as the key.
//
// Request: JSON runtime document
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
//
func PushRuntimeHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushRuntimeToCache(c, cache)
	}
}

// pushRuntimeToCache processes the runtime push request.
//
func pushRuntimeToCache(c fiber.Ctx, cache *data.Cache) error {
	runtime, err := parseRuntimeFromRequest(c)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "invalid runtime data" })
	}

	err = validateRuntimeData(runtime)
	if err != nil {
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "runtime validation failed" })
	}

	err = storeRuntimeInCache(cache, runtime)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "runtime cache error" })
	}

	return c.JSON(fiber.Map{ "reference": runtime.Reference })
}

// parseRuntimeFromRequest extracts runtime data from request body.
//
func parseRuntimeFromRequest(c fiber.Ctx) (*models.Runtime, error) {
	var runtime models.Runtime

	err := c.Bind().JSON(&runtime)
	if err != nil {
		return nil, err
	}

	return &runtime, nil
}

// validateRuntimeData ensures required fields are present and within limits.
//
func validateRuntimeData(runtime *models.Runtime) error {
	if runtime.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"reference required")
	}

	if runtime.State == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"state required")
	}

	// Validate state values
	validStates := map[string]bool{
		"idle":    true,
		"doing":   true,
		"done":    true,
		"aborted": true,
		"failed":  true,
	}

	if !validStates[runtime.State] {
		return fiber.NewError(fiber.StatusBadRequest,
			"state must be one of: idle, doing, done, aborted, failed")
	}

	if runtime.Session.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"session reference required")
	}

	if runtime.Queue.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"queue reference required")
	}

	if runtime.Queue.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"queue name required")
	}

	if runtime.Job.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"job reference required")
	}

	if runtime.Job.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"job name required")
	}

	if runtime.Task.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"task reference required")
	}

	if runtime.Task.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"task name required")
	}

	if runtime.Action.Reference == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"action reference required")
	}

	if runtime.Action.Name == "" {
		return fiber.NewError(fiber.StatusBadRequest,
			"action name required")
	}

	return nil
}

// storeRuntimeInCache saves runtime to cache storage.
//
func storeRuntimeInCache(cache *data.Cache, runtime *models.Runtime) error {
	return engines.PushRuntime(cache, *runtime)
}
