package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/data"
)

// GetProductHandler handles GET /service/products/:reference endpoint.
// Retrieves a single product from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the product reference
// Response: JSON product data or error details
//
// Fails fast on missing reference or cache retrieval error.
//
func GetProductHandler(cache *data.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getProductFromCache(c, cache)
	}
}

// getProductFromCache processes the single product retrieval request.
// Extracts reference from URL parameter and retrieves product from cache.
//
func getProductFromCache(c fiber.Ctx, cache *data.Cache) error {
	reference := c.Params("reference")
	if reference == "" {
		return sendError(c, fiber.StatusBadRequest,
            "reference parameter required",

			fiber.NewError(fiber.StatusBadRequest,
                "reference cannot be empty"))
	}

	product, err := cache.GetProduct("product:" + reference)
	if err != nil {
		return sendError(c, fiber.StatusNotFound,
            "product not found", err)
	}

	return sendProductResponse(c, product)
}

// sendProductResponse returns single product as JSON response.
func sendProductResponse(c fiber.Ctx, product interface{}) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"product": product,
	})
}
