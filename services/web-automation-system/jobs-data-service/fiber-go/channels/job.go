// Package channels provides process-lifecycle signal channels.
// Each channel is closed exactly once using sync.Once to prevent panics.
// Atomic flags allow non-blocking state checks without channel reads.
package channels

import (
	"sync"
	"sync/atomic"
)

var (
	shutdown_channel = make(chan struct{})
	shutdownOnce     sync.Once

	abort_channel = make(chan struct{})
	abortOnce     sync.Once
	aborted       int32

	kill_channel = make(chan struct{})
	killOnce     sync.Once
	killed       int32

	start_channel = make(chan struct{})
	startOnce     sync.Once
)

// GetShutdownChannel returns the channel closed on graceful shutdown.
func GetShutdownChannel() chan struct{} {
	return shutdown_channel
}

// SignalShutdown closes the shutdown channel exactly once.
// Triggers graceful shutdown of the data service.
func SignalShutdown() {
	shutdownOnce.Do(func() {
		close(shutdown_channel)
	})
}

// GetAbortChannel returns the channel closed on abort signal.
func GetAbortChannel() chan struct{} {
	return abort_channel
}

// SignalAbort sets the aborted flag and closes the abort channel once.
// Causes the child process to exit with abortExitCode so the supervisor
// launches the control child instead of restarting the data child.
func SignalAbort() {
	abortOnce.Do(func() {
		atomic.StoreInt32(&aborted, 1)
		close(abort_channel)
	})
}

// IsAbort reports whether an abort has been signalled.
func IsAbort() bool {
	return atomic.LoadInt32(&aborted) == 1
}

// GetKillChannel returns the channel closed on kill signal.
func GetKillChannel() chan struct{} {
	return kill_channel
}

// SignalKill sets the killed flag and closes the kill channel once.
// Causes the control child to exit with killExitCode so the supervisor
// terminates the parent process entirely.
func SignalKill() {
	killOnce.Do(func() {
		atomic.StoreInt32(&killed, 1)
		close(kill_channel)
	})
}

// IsKilled reports whether a kill has been signalled.
func IsKilled() bool {
	return atomic.LoadInt32(&killed) == 1
}

// GetStartChannel returns the channel closed on start signal.
func GetStartChannel() chan struct{} {
	return start_channel
}

// SignalStart closes the start channel exactly once.
// Unblocks the control server after the data child signals readiness.
func SignalStart() {
	startOnce.Do(func() {
		close(start_channel)
	})
}
