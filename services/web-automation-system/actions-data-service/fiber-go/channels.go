package main

import (
	"sync"
	"sync/atomic"
)

var (
	shutdown_channel = make(chan struct{})
	once sync.Once
	aborted int32
)

func GetShutdownChannel() chan struct{} {
	return shutdown_channel
}

func SignalShutdown() {
	once.Do(func() {
		close(shutdown_channel)
	})
}

func SignalAbort() {
	atomic.StoreInt32(&aborted, 1)
}

func IsAbort() bool {
	return atomic.LoadInt32(&aborted) == 1
}

func AbortAndShutdown() {
	SignalAbort()
	SignalShutdown()
}
