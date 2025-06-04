// Package main provides the entry point for the application.
package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"os/signal"
	"syscall"
	"time"
)

var (
	version = "dev"
	commit  = "none"
	date    = "unknown"
)

func main() {
	os.Exit(realMain())
}

func realMain() int {
	var (
		versionFlag = flag.Bool("version", false, "Show version information")
		configPath  = flag.String("config", "", "Path to configuration file")
		port        = flag.String("port", "8080", "Server port")
	)
	flag.Parse()

	if *versionFlag {
		fmt.Printf("gotemplate %s\nCommit: %s\nBuilt: %s\n", version, commit, date)
		return 0
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		<-sigChan
		fmt.Println("\nReceived shutdown signal, gracefully shutting down...")
		cancel()
	}()

	if err := run(ctx, *configPath, *port); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		return 1
	}

	return 0
}

func run(ctx context.Context, configPath, port string) error {
	_ = configPath // TODO: implement config loading

	fmt.Printf("Starting server on port %s...\n", port)

	// Wait for context cancellation
	<-ctx.Done()

	// Graceful shutdown
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()

	// Simulate shutdown process
	fmt.Println("Shutting down gracefully...")

	select {
	case <-shutdownCtx.Done():
		return fmt.Errorf("shutdown timeout exceeded")
	case <-time.After(100 * time.Millisecond): // Simulate quick shutdown
		fmt.Println("Shutdown complete")
		return nil
	}
}
