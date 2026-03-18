package main

import (
	"context"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"
	"github.com/tidwall/buntdb"

	"jobs-data-service/data"
)

func main() {
	cache, err := data.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName:      "jobs-data-service",

        ReadTimeout:  time.Second * 5,
		WriteTimeout: time.Second * 5,
		IdleTimeout:  time.Second * 5,
		BodyLimit:    1 * 1024 * 1024,

        ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("Fiber error [%d]: %v", code, err)

			return c.Status(code).JSON(fiber.Map{
				"error": err.Error(),
			})
		},
	})

	server.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))
	server.Use(logger.New())
	server.Use(cors.New())

	// Channel for manual shutdown trigger
	shutdownCh := make(chan struct{})

	serviceGroup := server.Group("/service")
	dataGroup := serviceGroup.Group("/data")
	jobsGroup := dataGroup.Group("/jobs")

    jobsGroup.Get("/health", func(c fiber.Ctx) error {
		err := cache.DB().View(func(tx *buntdb.Tx) error {
			return nil
		})

		if err != nil {
			return c.Status(fiber.StatusServiceUnavailable).JSON(fiber.Map{
				"status":  "unhealthy",
				"service": "jobs-data-service",
				"error":   "database connectivity failed",
			})
		}

		return c.JSON(fiber.Map{
			"status":  "healthy",
            "service": "jobs-data-service",
		})
	})

    jobsGroup.Post("/stop", func(c fiber.Ctx) error {
		go func() {
			shutdownCh <- struct{}{}
		}()

		return nil
	})

	RegisterJobRoutes(jobsGroup, cache)

	server.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"error": "Not Found",
			"path":  c.Path(),
		})
	})

	ctx, stop := signal.NotifyContext(context.Background(),
        os.Interrupt, syscall.SIGTERM)
	defer stop()

	go func() {
        port := os.Getenv("JOBS_DATA_SERVICE_PORT")

        if  port == "" {
            port = "4072"
        }

		if err := server.Listen(":" + port); err != nil {
			log.Printf("server listen error: %v", err)
		}
	}()

	// Wait for either signal or manual shutdown
	select {
	case <-ctx.Done():
		log.Println("received signal, shutting down data service...")
	case <-shutdownCh:
		log.Println("received shutdown request, shutting down data service...")
	}

	if err := server.Shutdown(); err != nil {
		log.Printf("server shutdown error: %v", err)
	}
}
