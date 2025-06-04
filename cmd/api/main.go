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
	version   = "dev"
	commit    = "none"
	date      = "unknown"
	buildTime = "unknown"
)

func main() {
	var (
		versionFlag = flag.Bool("version", false, "Show version information")
		configPath  = flag.String("config", "", "Path to configuration file")
		port        = flag.String("port", "8080", "Server port")
	)
	flag.Parse()

	if *versionFlag {
		fmt.Printf("Selektor %s\nCommit: %s\nBuilt: %s\n", version, commit, date)
		os.Exit(0)
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
		os.Exit(1)
	}
}

func run(ctx context.Context, configPath, port string) error {
	fmt.Printf("Starting Selektor on port %s...\n", port)
	
	<-ctx.Done()
	
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer shutdownCancel()
	
	select {
	case <-shutdownCtx.Done():
		return fmt.Errorf("shutdown timeout exceeded")
	default:
		fmt.Println("Shutdown complete")
		return nil
	}
}