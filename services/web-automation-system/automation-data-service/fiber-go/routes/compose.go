package routes

import (
	"automation-data-service/data"
	"log"

	"github.com/gofiber/fiber/v3"

	actionsData "actions-data-service/data"
	actionsRoutes "actions-data-service/routes"
	jobsData "jobs-data-service/data"
	jobsRoutes "jobs-data-service/routes"
	tasksData "tasks-data-service/data"
	tasksRoutes "tasks-data-service/routes"
)

func ComposeRoutes(dataGroup fiber.Router, cache *data.Cache) {
	actionsGroup := dataGroup.Group("/actions")
	actionsCache, err := actionsData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	actionsRoutes.RegisterActionsDataRoutes(actionsGroup, actionsCache)

	tasksGroup := dataGroup.Group("/tasks")
	tasksCache, err := tasksData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	tasksRoutes.RegisterTasksDataRoutes(tasksGroup, tasksCache)

	jobsGroup := dataGroup.Group("/jobs")
	jobsCache, err := jobsData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	jobsRoutes.RegisterJobsDataRoutes(jobsGroup, jobsCache)
}
