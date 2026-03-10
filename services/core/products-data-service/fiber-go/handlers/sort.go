package handlers

import (
	"github.com/gofiber/fiber/v3"

	"products-data-service/cache"
)

func SortProductHandler(cache *cache.Cache) fiber.Handler {
	return func(c fiber.Ctx) error {
		return nil
	}
}
