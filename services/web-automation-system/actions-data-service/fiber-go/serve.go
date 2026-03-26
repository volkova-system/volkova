package main

import (
	"actions-data-service/data"
	"actions-data-service/settings"
	"context"
	"log"
	"net"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func serve() {
	cache, err := data.Open()
	if err != nil {
		log.Fatal("cannot open cache:", err)
	}
	defer cache.Close()

	server := fiber.New(fiber.Config{
		AppName: settings.DataServiceName,

		ReadTimeout:  time.Second * 5,
		WriteTimeout: time.Second * 5,
		IdleTimeout:  time.Second * 5,
		BodyLimit:    1 * 1024 * 1024,

		ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("actions data service error [%d]: %v", code, err)

			return c.Status(code).JSON(fiber.Map{
				"issue": fiber.Map{
					"description": err.Error(),

					"method": c.Method(),
					"path":   c.Path(),
				},

				"service": settings.DataServiceName,
				"version": settings.Version,
			})
		},
	})

	server.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))
	server.Use(logger.New())
	server.Use(cors.New())

	serviceGroup := server.Group("/service")
	dataGroup := serviceGroup.Group("/data")
	actionsGroup := dataGroup.Group("/actions")

	RegisterActionsDataRoutes(actionsGroup, cache)

	server.Use(func(c fiber.Ctx) error {
		return c.Status(fiber.StatusNotFound).JSON(fiber.Map{
			"issue": fiber.Map{
				"description": "request not found",

				"method": c.Method(),
				"path":   c.Path(),
			},

			"service": settings.DataServiceName,
			"version": settings.Version,
		})
	})

	go func() {
		useFD := os.Getenv("ACTIONS_DATA_SERVICE_USE_FD") == "1" ||
			os.Getenv("USE_INHERITED_FD") == "1" ||
			os.Getenv("SOCKET_FD") != ""

		fd := uintptr(3)
		if v := os.Getenv("SOCKET_FD"); v != "" {
			if n, err := strconv.Atoi(v); err == nil && n >= 0 {
				fd = uintptr(n)
			}
		}

		if useFD {
			file := os.NewFile(fd, "listener")
			if file != nil {
				ln, err := net.FileListener(file)

				if err != nil {
					_ = file.Close()

					log.Printf("actions data service descriptor listener error: %v", err)

					SignalShutdown()
				} else {
					_ = file.Close()

					if err := server.Listener(ln); err != nil {
						_ = ln.Close()

						log.Printf("actions data service descriptor listener error: %v", err)

						SignalShutdown()
					}
				}
			}

			return
		}

		port := os.Getenv("ACTIONS_DATA_SERVICE_PORT")
		if port == "" {
			port = settings.DefaultPort
		}

		if err := server.Listen(":" + port); err != nil {
			log.Printf("actions data service listen error: %v", err)

			SignalShutdown()
		}
	}()

	ctx, stop := signal.NotifyContext(context.Background(),
		os.Interrupt, syscall.SIGTERM)
	defer stop()

	select {
	case <-ctx.Done():
		log.Println("received terminate signal, shutting down actions data service...")
	case <-GetShutdownChannel():
		log.Println("received shutdown request, shutting down actions data service...")
	case <-GetAbortChannel():
		log.Println("received abort request, shutting down actions data service...")
	}

	if err := server.Shutdown(); err != nil {
		log.Printf("actions data service shutdown error: %v", err)
	}
}
