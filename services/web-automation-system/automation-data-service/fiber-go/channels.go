package main

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

func GetShutdownChannel() chan struct{} {
	return shutdown_channel
}

func SignalShutdown() {
	shutdownOnce.Do(func() {
		close(shutdown_channel)
	})
}

func GetAbortChannel() chan struct{} {
	return abort_channel
}

func SignalAbort() {
	abortOnce.Do(func() {
		atomic.StoreInt32(&aborted, 1)
		close(abort_channel)
	})
}

func IsAbort() bool {
	return atomic.LoadInt32(&aborted) == 1
}

func GetKillChannel() chan struct{} {
	return kill_channel
}

func SignalKill() {
	killOnce.Do(func() {
		atomic.StoreInt32(&killed, 1)
		close(kill_channel)
	})
}

func IsKilled() bool {
	return atomic.LoadInt32(&killed) == 1
}

func GetStartChannel() chan struct{} {
	return start_channel
}

func SignalStart() {
	startOnce.Do(func() {
		close(start_channel)
	})
}
