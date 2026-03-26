package main

import (
	"actions-data-service/settings"
	"math"
	"math/rand"
	"time"

	"github.com/gofiber/fiber/v3"
)

// backoffNextECycle computes a restart delay using only the starting milliseconds.
// It shapes growth with Euler's number (e), phases it by the current second-of-minute,
// adds bounded randomization, and constrains the delay within one e-fold (start to start*e).
func backoffNextECycle(startingMilliseconds int) time.Duration {
	// Ensure the starting milliseconds are at least 1 to avoid degenerate or zero delays.
	if startingMilliseconds < 1 {
		startingMilliseconds = 1
	}

	// Define the minimum delay in milliseconds as the provided starting value.
	minimumDelayMilliseconds := float64(startingMilliseconds)

	// Define the maximum delay in milliseconds as one e-fold above the start (start * e).
	maximumDelayMilliseconds := minimumDelayMilliseconds * math.E

	// Capture the current second-of-minute (0..59) and bound it with modulo to remain in cycle.
	currentSecondOfMinute := time.Now().Second() % 60

	// Normalize the second-of-minute into the [0,1) interval to drive the growth curve smoothly.
	normalizedSecondPosition := float64(currentSecondOfMinute) / 60.0

	// Use Euler's number (e) as the base for the growth curve.
	eulerNumber := math.E

	// Prepare the denominator for the normalized exponential expression; guard against zero.
	denominatorForNormalization := eulerNumber - 1.0
	if denominatorForNormalization == 0.0 {
		denominatorForNormalization = 1.0
	}

	// Compute a normalized exponential growth factor in [0,1]:
	// (e^x - 1) / (e - 1), where x is the normalized second-of-minute.
	normalizedExponentialGrowth := (math.Exp(normalizedSecondPosition) - 1.0) / denominatorForNormalization

	// Interpolate the base delay in milliseconds between minimum and maximum using the growth factor.
	baseDelayMilliseconds := minimumDelayMilliseconds +
		normalizedExponentialGrowth*(maximumDelayMilliseconds-minimumDelayMilliseconds)

	// Choose a small jitter fraction relative to e to de-synchronize concurrent restarts.
	jitterFractionRelativeToEuler := 1.0 / (2.0 * eulerNumber)

	// Generate a uniform random value in [-1, +1] to vary the delay up or down within the jitter band.
	uniformRandomBetweenMinusOneAndOne := 2.0*rand.Float64() - 1.0

	// Compute a multiplicative jitter (1 ± fraction) and apply it to the base delay.
	jitterMultiplier := 1.0 + jitterFractionRelativeToEuler*uniformRandomBetweenMinusOneAndOne

	// Apply jitter to the base delay in milliseconds.
	unclampedDelayMilliseconds := baseDelayMilliseconds * jitterMultiplier

	// Clamp the jittered delay to always remain within [start, start*e].
	clampedDelayMilliseconds := math.Min(
		maximumDelayMilliseconds,
		math.Max(minimumDelayMilliseconds, unclampedDelayMilliseconds),
	)

	// Round to the nearest millisecond and convert to time.Duration for sleeping.
	roundedMilliseconds := math.Round(clampedDelayMilliseconds)
	return time.Duration(roundedMilliseconds) * time.Millisecond
}

// issueResponse creates a consistent issue response format for the API.
// It returns a standardized JSON issue structure with the given status code,
// description, and includes the request method and path for debugging.
func issueResponse(c fiber.Ctx, statusCode int, description string) error {
	return c.Status(statusCode).JSON(fiber.Map{
		"issue": fiber.Map{
			"description": description,
			"method":      c.Method(),
			"path":        c.Path(),
		},

		"service": settings.DataServiceName,
		"version": settings.Version,
	})
}
