package handlers

import (
	"strconv"

	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

// FilterProductHandler handles GET /service/products/filter endpoint.
// Accepts field, value, skip and limit query parameters for filtering products.
// Returns paginated list of products matching the filter criteria from cache
// storage.
//
// Query Parameters:
//   - field:   Field name to filter by (required)
//              (e.g., "brandName", "keywords", or custom field)
//
//   - value:   Value to match against the specified field (required)
//
//   - skip:    Number of matching products to skip (default: 0)
//
//   - limit:   Maximum products to return (default: 10)
//
// Response: JSON array of filtered products or error details
//
// Fails fast on missing field/value parameters or any cache retrieval error.
//
func FilterProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return filterProductsInCache(c, cache)
	}
}

// filterProductsInCache processes the product filter request.
// Parses field, value and pagination parameters and retrieves filtered products
// from cache.
//
func filterProductsInCache(c fiber.Ctx, cache *cache.Cache) error {
	field, value, skip, limit, err := parseFilterParams(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest, "invalid parameters", err)
	}

	products, err := filterProductsFromCache(cache, field, value, skip, limit)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache filter error", err)
	}

	total, err := getFilterCount(cache, field, value)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
			"cache filter count error", err)
	}

	return sendFilterResponse(c, products, field, value, skip, limit, total)
}

// parseFilterParams extracts field, value, skip and limit from query parameters.
// Sets defaults: skip=0, limit=10. Field and value parameters are required.
//
func parseFilterParams(c fiber.Ctx) (string, string, int, int, error) {
	field := c.Query("field")
	if field == "" {
		return "", "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
			"field parameter is required")
	}

	value := c.Query("value")
	if value == "" {
		return "", "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
			"value parameter is required")
	}

	skip := 0
	limit := 10

	if skipParam := c.Query("skip"); skipParam != "" {
		parsedSkip, err := strconv.Atoi(skipParam)
		if err != nil {
			return "", "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"skip must be integer")
		}

		skip = parsedSkip
	}

	if limitParam := c.Query("limit"); limitParam != "" {
		parsedLimit, err := strconv.Atoi(limitParam)
		if err != nil {
			return "", "", 0, 0, fiber.NewError(fiber.StatusBadRequest,
				"limit must be integer")
		}

		limit = parsedLimit
	}

	return field, value, skip, limit, nil
}

// filterProductsFromCache filters products in cache with pagination.
//
func filterProductsFromCache(cache *cache.Cache,
    field, value string, skip, limit int) (interface{}, error) {
	return cache.FilterProducts(skip, limit, field, value)
}

// getFilterCount returns the total count of products matching the filter criteria.
// Since there's no dedicated GetFilterCount method in cache, we use FilterProducts
// with a large limit to get all matching products and count them.
//
func getFilterCount(cache *cache.Cache, field, value string) (int, error) {
	// Get all matching products to count them
	products, err := cache.FilterProducts(0, 10000, field, value)
	if err != nil {
		return 0, err
	}

	return len(products), nil
}

// sendFilterResponse returns filter results as JSON response
// with filter criteria and pagination metadata.
func sendFilterResponse(c fiber.Ctx, products interface{},
	field, value string, skip, limit, total int) error {
    pages, page := computePageData(skip, limit, total)

    return c.JSON(fiber.Map{
		"status":   "success",

		"products": products,
		"field":    field,
		"value":    value,

		"skip":     skip,
		"limit":    limit,
		"total":    total,
        "pages":    pages,
        "page":     page,
	})
}
