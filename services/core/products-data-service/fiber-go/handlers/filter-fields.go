package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// GetFilterFieldsProductHandler handles GET /service/products/filter/fields endpoint.
// Returns all unique filter fields with their possible values from cache storage.
//
// Response: JSON object with filter field values map and count or error details
//
// Fails fast on any cache retrieval error.
//
func GetFilterFieldsProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return getFilterFieldsFromCache(c, cache)
	}
}

// getFilterFieldsFromCache processes the filter fields request.
// Retrieves all unique filter fields with their values from cache.
//
func getFilterFieldsFromCache(c fiber.Ctx, cache *cache.Cache) error {
	fieldValues, err := retrieveFilterFieldsFromCache(cache)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError, "cache error", err)
	}

	return sendFilterFieldsResponse(c, fieldValues)
}

// retrieveFilterFieldsFromCache gets filter field values from cache.
//
func retrieveFilterFieldsFromCache(cache *cache.Cache) (interface{}, error) {
	return cache.GetFilterFieldValues()
}

// sendFilterFieldsResponse returns filter field values as JSON response
// with count metadata.
//
func sendFilterFieldsResponse(c fiber.Ctx, fieldValues interface{}) error {
	// Convert to map to get count (assuming fieldValues is a map[string][]string)
	var count int
	if fieldValuesMap, ok := fieldValues.(map[string][]string); ok {
		count = len(fieldValuesMap)
	}

	return c.JSON(fiber.Map{
		"status":       "success",
		"filterFields": fieldValues,
		"count":        count,
	})
}
