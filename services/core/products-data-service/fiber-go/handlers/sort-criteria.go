package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

func GetSortCriteriaProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		// Get all unique sort criteria from cache
		criteria, err := cache.GetSortCriteria()
		if err != nil {
			return c.Status(fiber.StatusInternalServerError).JSON(fiber.Map{
				"error":   "Failed to retrieve sort criteria",
				"message": err.Error(),
			})
		}

		// Return the sort criteria
		return c.JSON(fiber.Map{
			"sortCriteria": criteria,
			"count":        len(criteria),
		})
	}
}
