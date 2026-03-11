package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// GetSortCriteriaProductHandler handles GET /service/products/sort/criteria endpoint.
// Returns all unique sort criteria available for products from cache storage.
//
// Response: JSON object with sort criteria list and count or error details
//
// Fails fast on any cache retrieval error.
//
func GetSortCriteriaProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getSortCriteriaFromCache(c, cache)
	}
}

// getSortCriteriaFromCache processes the sort criteria request.
// Retrieves all unique sort criteria from cache.
//
func getSortCriteriaFromCache(c fiber.Ctx, cache *cache.Cache) error {
	criteria, err := retrieveSortCriteriaFromCache(cache)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache error", err)
	}

	return sendSortCriteriaResponse(c, criteria)
}

// retrieveSortCriteriaFromCache gets sort criteria from cache.
//
func retrieveSortCriteriaFromCache(cache *cache.Cache) (interface{}, error) {
	return cache.GetSortCriteria()
}

// sendSortCriteriaResponse returns sort criteria as JSON response
// with count metadata.
//
func sendSortCriteriaResponse(c fiber.Ctx, criteria interface{}) error {
	// Convert to slice to get count (assuming criteria is a slice)
	var count int
	if criteriaSlice, ok := criteria.([]interface{}); ok {
		count = len(criteriaSlice)

	} else if criteriaSlice, ok := criteria.([]string); ok {
		count = len(criteriaSlice)
	}

	return c.JSON(fiber.Map{
		"status":       "success",
		"sortCriteria": criteria,
		"count":        count,
	})
}
