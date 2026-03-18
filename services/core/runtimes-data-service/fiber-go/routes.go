package main

import (
	"github.com/gofiber/fiber/v3"

	"runtimes-data-service/data"
	"runtimes-data-service/handlers"
)

func RegisterRuntimeRoutes(runtimesGroup fiber.Router, cache *data.Cache) {
	runtimesGroup.Get("/",
        handlers.GetRuntimesHandler(cache))

    runtimesGroup.Post("/push",
        handlers.PushRuntimeHandler(cache))

	runtimesGroup.Delete("/pop/:reference",
        handlers.PopRuntimeHandler(cache))

	runtimesGroup.Get("/:reference",
        handlers.GetRuntimeHandler(cache))
}
