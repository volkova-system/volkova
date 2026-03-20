package main

import (
	"github.com/gofiber/fiber/v3"

	"sessions-data-service/data"
	"sessions-data-service/handlers"
)

func RegisterSessionRoutes(sessionsGroup fiber.Router, cache *data.Cache) {
	sessionsGroup.Get("/",
        handlers.GetSessionsHandler(cache))

    sessionsGroup.Post("/push",
        handlers.PushSessionHandler(cache))

	sessionsGroup.Delete("/pop/:reference",
        handlers.PopSessionHandler(cache))

	sessionsGroup.Get("/:reference",
        handlers.GetSessionHandler(cache))
}
