package handlers

import (
	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/data"
	"runtimes-data-service/engines"
)

// GetRuntimeHandler handles GET /service/data/runtimes/:reference endpoint.
// Retrieves a single runtime from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the runtime reference
// Response: JSON runtime data or error details
//
// Fails fast on missing reference or cache retrieval error.
//
func GetRuntimeHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getRuntimeFromCache(c, cache)
	}
}

// getRuntimeFromCache processes the single runtime retrieval request.
//
func getRuntimeFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
			"reference parameter required",
			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	runtime, err := engines.GetRuntime(cache, "runtime:"+reference)
	if err != nil {
		return sendError(c, fiber.StatusNotFound,
			"runtime not found", err)
	}

	return sendRuntimeResponse(c, runtime)
}

// sendRuntimeResponse returns single runtime as JSON response.
//
func sendRuntimeResponse(c fiber.Ctx, runtime any) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"runtime": runtime,
	})
}
