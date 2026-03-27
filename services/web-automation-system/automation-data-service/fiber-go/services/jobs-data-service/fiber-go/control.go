package main

import (
	"log"
	"net"
	"os"
	"strconv"
	"time"

	"jobs-data-service/handlers"
	"jobs-data-service/settings"

	"github.com/gofiber/fiber/v3"
	"github.com/gofiber/fiber/v3/middleware/cors"
	"github.com/gofiber/fiber/v3/middleware/logger"
	"github.com/gofiber/fiber/v3/middleware/recover"
)

func RunControl() {
	server := fiber.New(fiber.Config{
		AppName: settings.DataServiceName,

		ReadTimeout:  time.Second * 5,
		WriteTimeout: time.Second * 5,
		IdleTimeout:  time.Second * 5,

		ErrorHandler: func(c fiber.Ctx, err error) error {
			code := fiber.StatusInternalServerError
			if e, ok := err.(*fiber.Error); ok {
				code = e.Code
			}

			log.Printf("jobs data control service error [%d]: %v", code, err)

			return handlers.IssueResponse(c, code, err.Error())
		},
	})

	server.Use(recover.New(recover.Config{
		EnableStackTrace: true,
	}))
	server.Use(logger.New())
	server.Use(cors.New())

	serviceGroup := server.Group("/service")
	dataGroup := serviceGroup.Group("/data")
	jobsGroup := dataGroup.Group("/jobs")

	RegisterJobsControlRoutes(jobsGroup)

	server.Use(func(c fiber.Ctx) error {
		return handlers.IssueResponse(c, fiber.StatusNotFound, "request not found")
	})

	go func() {
		useFD := os.Getenv("JOBS_DATA_SERVICE_USE_FD") == "1" ||
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

					log.Printf("jobs data control service descriptor listener error: %v", err)

					SignalKill()
				} else {
					_ = file.Close()

					if err := server.Listener(ln); err != nil {
						_ = ln.Close()

						log.Printf("jobs data control service descriptor listener error: %v", err)

						SignalKill()
					}
				}
			}

			return
		}

		port := os.Getenv("JOBS_DATA_SERVICE_PORT")
		if port == "" {
			port = settings.DefaultPort
		}

		if err := server.Listen(":" + port); err != nil {
			log.Printf("jobs data control service listen error: %v", err)

			SignalKill()
		}
	}()

	select {
	case <-GetStartChannel():
	case <-GetKillChannel():
	}

	if err := server.Shutdown(); err != nil {
		log.Printf("jobs data control service shutdown error: %v", err)
	}
}
