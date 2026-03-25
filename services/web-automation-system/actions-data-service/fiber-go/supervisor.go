package main

import (
	"log"
	"net"
	"os"
	"os/exec"
	"runtime"
	"time"
)

const (
	abortExitCode = 200
	killExitCode = 201
)

func runParent() {
	port := os.Getenv("ACTIONS_DATA_SERVICE_PORT")
	if port == "" {
		port = "4071"
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
			cmd.Env = append(os.Environ(), "ACTIONS_DATA_SERVICE_USE_FD=1", "USE_INHERITED_FD=1", "SOCKET_FD=3")
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
					ctrl.Env = append(os.Environ(), "ACTIONS_DATA_SERVICE_USE_FD=1", "USE_INHERITED_FD=1", "SOCKET_FD=3", "ACTIONS_DATA_SERVICE_MODE=control")
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

			time.Sleep(300 * time.Millisecond)
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
					ctrl.Env = append(os.Environ(), "ACTIONS_DATA_SERVICE_MODE=control")
					if err := ctrl.Start(); err != nil {
						log.Printf("control child start error: %v", err)
						time.Sleep(3 * time.Second)

						continue
					}

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

			time.Sleep(300 * time.Millisecond)
		}
	}
}


func runChild() {
	if os.Getenv("ACTIONS_DATA_SERVICE_MODE") == "control" {
		control()
		return
	}

	serve()

	if IsKilled() {
		os.Exit(killExitCode)
	}

	if IsAbort() {
		os.Exit(abortExitCode)
	}
}
