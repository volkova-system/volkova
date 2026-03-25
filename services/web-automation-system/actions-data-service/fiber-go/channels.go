package main

import "sync"

var (
	shutdown_channel = make(chan struct{})
	once sync.Once
)

func GetShutdownChannel() chan struct{} {
	return shutdown_channel
}

func SignalShutdown() {
	once.Do(func() {
		close(shutdown_channel)
	})
}
