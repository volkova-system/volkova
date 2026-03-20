package handlers

import (
	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/data"
	"runtimes-data-service/engines"
)

// PopRuntimeHandler handles DELETE /service/data/runtimes/pop/:reference endpoint.
// Removes a runtime from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the runtime reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
//
func PopRuntimeHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popRuntimeFromCache(c, cache)
	}
}

// popRuntimeFromCache processes the runtime removal request.
//
func popRuntimeFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return c.Status(fiber.StatusBadRequest).JSON(
			fiber.Map{ "error": "runtime reference cannot be empty" })
	}

	runtime, err := engines.PopRuntime(cache, "runtime:"+reference)
	if err != nil {
		return c.Status(fiber.StatusInternalServerError).JSON(
			fiber.Map{ "error": "runtime cache error" })
	}

	return c.JSON(fiber.Map{ "runtime": runtime })
}
