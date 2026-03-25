package main

import (
	"sync"
	"sync/atomic"
)

var (
	shutdown_channel = make(chan struct{})
	shutdownOnce sync.Once

	abort_channel = make(chan struct{})
	abortOnce sync.Once
	aborted int32
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
