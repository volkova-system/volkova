package main

import (
	"log"
	"math"
	"math/rand"
	"net"
	"os"
	"os/exec"
	"runtime"
	"sessions-data-service/settings"
	"time"

	"sessions-data-service/channels"
)

const (
	abortExitCode = 200
	killExitCode  = 201
)

func RunParent() {
	port := os.Getenv("SESSIONS_DATA_SERVICE_PORT")
	if port == "" {
		port = settings.DefaultPort
	}

	if runtime.GOOS != "windows" {
		ln, err := net.Listen("tcp", ":"+port)
		if err != nil {
			log.Fatal(err)
		}

		tcpLn, ok := ln.(*net.TCPListener)
		if !ok {
			log.Fatal("not a tcp listener")
		}

		for {
			f, err := tcpLn.File()
			if err != nil {
				log.Printf("listener file error: %v", err)
				time.Sleep(3 * time.Second)

				continue
			}

			cmd := exec.Command(os.Args[0], "child")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			cmd.Env = append(os.Environ(), "SESSIONS_DATA_SERVICE_USE_FD=1", "USE_INHERITED_FD=1", "SOCKET_FD=3")
			cmd.ExtraFiles = []*os.File{f}
			if err := cmd.Start(); err != nil {
				log.Printf("child start error: %v", err)
				_ = f.Close()
				time.Sleep(3 * time.Second)

				continue
			}
			_ = f.Close()

			err = cmd.Wait()
			code := 0
			if cmd.ProcessState != nil {
				code = cmd.ProcessState.ExitCode()
			}
			if code == abortExitCode {
				log.Printf("child aborted, starting control child")
				for {
					f2, err := tcpLn.File()
					if err != nil {
						log.Printf("listener file error: %v", err)
						time.Sleep(3 * time.Second)

						continue
					}

					ctrl := exec.Command(os.Args[0], "child")
					ctrl.Stdout = os.Stdout
					ctrl.Stderr = os.Stderr
					ctrl.Env = append(os.Environ(), "SESSIONS_DATA_SERVICE_USE_FD=1", "USE_INHERITED_FD=1", "SOCKET_FD=3", "SESSIONS_DATA_SERVICE_MODE=control")
					ctrl.ExtraFiles = []*os.File{f2}
					if err := ctrl.Start(); err != nil {
						log.Printf("control child start error: %v", err)
						_ = f2.Close()
						time.Sleep(3 * time.Second)

						continue
					}

					_ = f2.Close()
					_ = ctrl.Wait()
					code2 := 0
					if ctrl.ProcessState != nil {
						code2 = ctrl.ProcessState.ExitCode()
					}
					if code2 == killExitCode {
						log.Printf("control child requested termination; exiting parent")
						return
					}

					log.Printf("control child exited; restarting data child")

					break
				}

				continue
			}

			if err != nil {
				log.Printf("child exited with error: %v", err)
			} else {
				log.Printf("child exited")
			}

			time.Sleep(backoffNextECycle(300))
		}
	} else {
		for {
			cmd := exec.Command(os.Args[0], "child")
			cmd.Stdout = os.Stdout
			cmd.Stderr = os.Stderr
			cmd.Env = os.Environ()
			if err := cmd.Start(); err != nil {
				log.Printf("child start error: %v", err)
				time.Sleep(3 * time.Second)

				continue
			}

			err := cmd.Wait()
			code := 0
			if cmd.ProcessState != nil {
				code = cmd.ProcessState.ExitCode()
			}

			if code == abortExitCode {
				log.Printf("child aborted, starting control child")
				for {
					ctrl := exec.Command(os.Args[0], "child")
					ctrl.Stdout = os.Stdout
					ctrl.Stderr = os.Stderr
					ctrl.Env = append(os.Environ(), "SESSIONS_DATA_SERVICE_MODE=control")
					if err := ctrl.Start(); err != nil {
						log.Printf("control child start error: %v", err)
						time.Sleep(3 * time.Second)

						continue
					}

					_ = ctrl.Wait()
					killCode := 0
					if ctrl.ProcessState != nil {
						killCode = ctrl.ProcessState.ExitCode()
					}
					if killCode == killExitCode {
						log.Printf("control child requested termination; exiting parent")
						return
					}

					log.Printf("control child exited; restarting data child")

					break
				}

				continue
			}

			if err != nil {
				log.Printf("child exited with error: %v", err)
			} else {
				log.Printf("child exited")
			}

			time.Sleep(backoffNextECycle(300))
		}
	}
}

func RunChild() {
	if os.Getenv("SESSIONS_DATA_SERVICE_MODE") == "control" {
		RunControl()

		if channels.IsKilled() {
			os.Exit(killExitCode)
		}

		return
	}

	ServeData()

	if channels.IsAbort() {
		os.Exit(abortExitCode)
	}
}

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
