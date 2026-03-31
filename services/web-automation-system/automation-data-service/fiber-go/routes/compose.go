package routes

import (
	"automation-data-service/data"
	"log"

	"github.com/gofiber/fiber/v3"

	actionsData "actions-data-service/data"
	actionsRoutes "actions-data-service/routes"
	jobsData "jobs-data-service/data"
	jobsRoutes "jobs-data-service/routes"
	queuesData "queues-data-service/data"
	queuesRoutes "queues-data-service/routes"
	runtimesData "runtimes-data-service/data"
	runtimesRoutes "runtimes-data-service/routes"
	sessionsData "sessions-data-service/data"
	sessionsRoutes "sessions-data-service/routes"
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

	queuesGroup := dataGroup.Group("/queues")
	queuesCache, err := queuesData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	queuesRoutes.RegisterQueuesDataRoutes(queuesGroup, queuesCache)

	sessionsGroup := dataGroup.Group("/sessions")
	sessionsCache, err := sessionsData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	sessionsRoutes.RegisterSessionsDataRoutes(sessionsGroup, sessionsCache)

	runtimesGroup := dataGroup.Group("/runtimes")
	runtimesCache, err := runtimesData.SetupCache(cache.Name(), cache.DB(), cache.Path())
	if err != nil {
		log.Fatal(err)
	}
	runtimesRoutes.RegisterRuntimesDataRoutes(runtimesGroup, runtimesCache)
}
