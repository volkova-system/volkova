package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
	"products-data-service/model"
)

// PushProductHandler handles POST /service/products/push endpoint.
// Accepts JSON-LD product document and stores it in cache using
// cacheIdentifier.value as the key.
//
// Request: JSON-LD product document matching core-product-schema.waste
// Response: Success confirmation or error details
//
// Fails fast on any validation or storage error.
func PushProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return pushProductToCache(c, cache)
	}
}

// pushProductToCache processes the product push request.
// Parses JSON-LD product data and stores it in cache.
func pushProductToCache(c fiber.Ctx, cache *cache.Cache) error {
	product, err := parseProductFromRequest(c)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "invalid product data", err)
	}

	err = validateProductData(product)
	if err != nil {
		return sendError(c, fiber.StatusBadRequest,
            "validation failed", err)
	}

	err = storeProductInCache(cache, product)
	if err != nil {
		return sendError(c, fiber.StatusInternalServerError,
            "cache error", err)
	}

	return sendSuccess(c, "product pushed successfully")
}

// parseProductFromRequest extracts product data from request body.
func parseProductFromRequest(c fiber.Ctx) (*model.Product, error) {
	var product model.Product

	err := c.Bind().JSON(&product)
	if err != nil {
		return nil, err
	}

	return &product, nil
}

// validateProductData ensures required fields are present.
func validateProductData(product *model.Product) error {
	if product.CacheIdentifier.Value == "" {
		return fiber.NewError(fiber.StatusBadRequest,
            "cache identifier required")
	}

	if product.SKU == "" {
		return fiber.NewError(fiber.StatusBadRequest,
            "sku required")
	}

	return nil
}

// storeProductInCache saves product to cache storage.
func storeProductInCache(cache *cache.Cache, product *model.Product) error {
	return cache.PushProduct(*product)
}



// sendSuccess returns standardized success response.
func sendSuccess(c fiber.Ctx, message string) error {
	return c.JSON(fiber.Map{
		"status":  "success",
		"message": message,
	})
}
