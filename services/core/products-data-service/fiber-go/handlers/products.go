package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// GetProductsHandler handles GET /service/products endpoint.
// Accepts skip and limit query parameters for pagination.
// Returns paginated list of products from cache storage.
//
// Query Parameters:
//   - skip: Number of products to skip (default: 0)
//   - limit: Maximum products to return (default: 10)
//
// Response: JSON array of products or error details
//
// Fails fast on any cache retrieval error.
func GetProductsHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getProductsFromCache(c, cache)
	}
}

// getProductsFromCache processes the products list request.
// Parses pagination parameters and retrieves products from cache.
func getProductsFromCache(c fiber.Ctx, cache *cache.Cache) error {
	skip, limit, err := parsePaginationParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "invalid parameters", err)
	}

	products, err := retrieveProductsFromCache(cache, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache error", err)
	}

	total, err := cache.GetProductCount()
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache count error", err)
	}

	return sendProductsResponse(c, products, skip, limit, total)
}

// parsePaginationParams extracts skip and limit from query parameters.
// Sets defaults: skip=0, limit=10.
func parsePaginationParams(c fiber.Ctx) (int, int, error) {
	skip := 0
	limit := 10

	if skipParam := c.Query("skip"); skipParam != "" {
		parsedSkip, err := strconv.Atoi(skipParam)
		if err != nil {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be integer")
		}

		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}

		limit = parsedLimit
	}

	return skip, limit, nil
}

// retrieveProductsFromCache gets products from cache with pagination.
func retrieveProductsFromCache(cache *cache.Cache, skip, limit int) (
	interface{}, error) {
	return cache.GetProducts(skip, limit)
}

// sendProductsResponse returns products list as JSON response
// with pagination metadata.
func sendProductsResponse(c fiber.Ctx, products interface{},
    skip, limit, total int) error {
	return c.JSON(fiber.Map{
		"status":   "success",
		"products": products,
		"skip":  skip,
        "limit": limit,
        "total": total,
	})
}
