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
		return sendError(c, fiber.StatusBadRequest,
            "invalid runtime data", err)
	}

	err = validateRuntimeData(runtime)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "validation failed", err)
	}

	err = storeRuntimeInCache(cache, runtime)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache error", err)
	}

	return sendSuccess(c, "runtime pushed")
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

	return nil
}

// storeRuntimeInCache saves runtime to cache storage.
//
func storeRuntimeInCache(cache *data.Cache, runtime *models.Runtime) error {
	return engines.PushRuntime(cache, *runtime)
}
