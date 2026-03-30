package handlers

import (
"errors"

"github.com/gofiber/fiber/v3"
"github.com/tidwall/buntdb"

"queues-data-service/data"
"queues-data-service/engines"
)

// PopQueueHandler handles DELETE /service/data/queues/pop/:reference endpoint.
// Removes a queue from cache using the provided reference parameter.
//
// Request: URL parameter 'reference' containing the queue reference
// Response: Success confirmation or error details
//
// Fails fast on missing reference or cache removal error.
func PopQueueHandler(cache *data.Cache) fiber.Handler {
return func(c fiber.Ctx) error {
return popQueueFromCache(c, cache)
}
}

// popQueueFromCache processes the queue removal request.
func popQueueFromCache(c fiber.Ctx, cache *data.Cache) error {
reference := c.Params("reference")
if reference == "" {
return IssueResponse(c, fiber.StatusBadRequest, "queue reference cannot be empty")
}

queue, err := engines.PopQueue(cache, "queue:"+reference)
if err != nil {
if errors.Is(err, buntdb.ErrNotFound) {
return IssueResponse(c, fiber.StatusNotFound, "queue not found")
}

return IssueResponse(c, fiber.StatusInternalServerError, "queue cache error")
}

return c.JSON(fiber.Map{"queue": queue})
}
