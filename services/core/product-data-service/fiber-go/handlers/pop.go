package handlers

import (
	"github.com/gofiber/fiber/v3"

	"product-data-service/cache"
)

// PopProductHandler handles DELETE /service/products/pop/:reference endpoint.
// Removes a product from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the product reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
func PopProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return popProductFromCache(c, cache)
	}
}

// popProductFromCache processes the product removal request.
// Extracts reference from URL parameter and removes product from cache.
func popProductFromCache(c fiber.Ctx, cache *cache.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest, "reference parameter required",
			fiber.NewError(fiber.StatusBadRequest, "reference cannot be empty"))
	}

	err := cache.PopProduct("product:" + reference)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError, "cache error", err)
	}

	return sendSuccess(c, "product removed successfully")
}
