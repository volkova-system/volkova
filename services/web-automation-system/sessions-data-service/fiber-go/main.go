// Package main is the entry point for the sessions-data-service binary.
//
// The binary operates in two modes selected by the first CLI argument:
//   - "child": runs the child process (data server or control server).
//   - (default): runs the parent supervisor process.
//
// The supervisor (RunParent) owns the TCP listener and spawns child
// processes, restarting them on exit. The child (RunChild) runs either
// the data server (ServeData) or the control server (RunControl)
// depending on the SESSIONS_DATA_SERVICE_MODE environment variable.
package main

import (
	"os"
)

// main selects the execution mode based on CLI arguments.
// Passing "child" as the first argument runs the child process;
// omitting it runs the parent supervisor.
func main() {
	if len(os.Args) > 1 && os.Args[1] == "child" {
		RunChild()

		return
	}

	RunParent()
}
