package main

import (
	"github.com/gofiber/fiber/v3"

	"queues-data-service/data"
	"queues-data-service/handlers"
)

func RegisterQueueRoutes(queuesGroup fiber.Router, cache *data.Cache) {
	queuesGroup.Get("/",
        handlers.GetQueuesHandler(cache))

    queuesGroup.Post("/push",
        handlers.PushQueueHandler(cache))

	queuesGroup.Delete("/pop/:reference",
        handlers.PopQueueHandler(cache))

	queuesGroup.Get("/:reference",
        handlers.GetQueueHandler(cache))
}
