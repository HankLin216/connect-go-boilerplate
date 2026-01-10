package main

import (
	"context"
	"flag"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"connectrpc.com/connect"
	v1 "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1"
	"github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
)

var (
	serverAddr = flag.String("addr", "http://localhost:30814", "Server address")
	interval   = flag.Duration("interval", 300*time.Millisecond, "Call interval")
	timeout    = flag.Duration("timeout", 10*time.Second, "Request timeout")
	clientName = flag.String("name", "TestClient", "Client name prefix")
	enableTLS  = flag.Bool("tls", false, "Whether to use HTTPS")
)

func main() {
	flag.Parse()

	// Adjust address based on TLS settings
	addr := *serverAddr
	if *enableTLS && !contains(addr, "https://") {
		addr = "https://" + removeProtocol(addr)
	} else if !*enableTLS && !contains(addr, "http://") {
		addr = "http://" + removeProtocol(addr)
	}

	// Create HTTP client
	client := &http.Client{
		Timeout: *timeout,
	}

	// Create Connect client
	greeterClient := greeterv1connect.NewGreeterClient(client, addr)

	// Create cancellable context
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Handle system signals
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Statistics
	var successCount, failureCount int

	// Create ticker
	ticker := time.NewTicker(*interval)
	defer ticker.Stop()

	fmt.Printf("🚀 Start calling SayHello API every %v\n", *interval)
	fmt.Printf("📡 Server address: %s\n", addr)
	fmt.Printf("⏰ Timeout: %v\n", *timeout)
	fmt.Printf("👤 Client name: %s\n", *clientName)
	fmt.Println("Press Ctrl+C to stop...")
	fmt.Println(strings.Repeat("-", 50))

	counter := 0

	for {
		select {
		case <-sigChan:
			fmt.Println("\n📊 Statistics:")
			fmt.Printf("✅ Success: %d times\n", successCount)
			fmt.Printf("❌ Failed: %d times\n", failureCount)
			fmt.Printf("📈 Success rate: %.2f%%\n", float64(successCount)/float64(successCount+failureCount)*100)
			fmt.Println("👋 Goodbye!")
			return

		case <-ticker.C:
			counter++

			// Create context with timeout
			reqCtx, reqCancel := context.WithTimeout(ctx, *timeout)

			// Create request
			req := connect.NewRequest(&v1.HelloRequest{
				Name: fmt.Sprintf("%s-%d", *clientName, counter),
			})

			// Add request headers (optional)
			req.Header().Set("User-Agent", "connect-go-client/1.0")
			req.Header().Set("X-Client-Version", "1.0.0")

			start := time.Now()

			// Call API
			resp, err := greeterClient.SayHello(reqCtx, req)

			duration := time.Since(start)
			reqCancel()

			if err != nil {
				failureCount++
				log.Printf("❌ [%d] Call failed (%v): %v", counter, duration, err)
				continue
			}

			successCount++
			fmt.Printf("✅ [%d] Response (%v): %s\n", counter, duration, resp.Msg.Message)
		}
	}
}

// Helper functions
func contains(s, substr string) bool {
	return len(s) >= len(substr) && s[:len(substr)] == substr
}

func removeProtocol(addr string) string {
	if contains(addr, "https://") {
		return addr[8:]
	}
	if contains(addr, "http://") {
		return addr[7:]
	}
	return addr
}
