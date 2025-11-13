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
	greeterv1 "github.com/HankLin216/connect-go-boilerplate/api/greeter/v1"
	"github.com/HankLin216/connect-go-boilerplate/api/greeter/v1/greeterv1connect"
	userv1 "github.com/HankLin216/connect-go-boilerplate/api/user/v1"
	"github.com/HankLin216/connect-go-boilerplate/api/user/v1/userv1connect"
)

var (
	serverAddr = flag.String("addr", "http://connect-go.phison.com", "Server address")
	interval   = flag.Duration("interval", 300*time.Millisecond, "Call interval")
	timeout    = flag.Duration("timeout", 10*time.Second, "Request timeout")
	clientName = flag.String("name", "TestClient", "Client name prefix")
	enableTLS  = flag.Bool("tls", false, "Whether to use HTTPS")
	useHTTPGet = flag.Bool("get", true, "Use HTTP GET for idempotent requests")
	testUser   = flag.Bool("user", false, "Test User service instead of Greeter")
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

	// Create Connect clients with HTTP GET support
	var clientOptions []connect.ClientOption
	if *useHTTPGet {
		clientOptions = append(clientOptions, connect.WithHTTPGet())
	}

	greeterClient := greeterv1connect.NewGreeterClient(client, addr, clientOptions...)
	userClient := userv1connect.NewUserClient(client, addr, clientOptions...)

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

	service := "Greeter"
	if *testUser {
		service = "User"
	}

	fmt.Printf("🚀 Start calling %s API every %v\n", service, *interval)
	fmt.Printf("📡 Server address: %s\n", addr)
	fmt.Printf("⏰ Timeout: %v\n", *timeout)
	fmt.Printf("👤 Client name: %s\n", *clientName)
	fmt.Printf("🌐 HTTP GET enabled: %v\n", *useHTTPGet)
	fmt.Printf("📋 Testing service: %s\n", service)
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

			start := time.Now()
			var err error
			var message string

			if *testUser {
				// Test User service (supports HTTP GET)
				// Use fixed name for caching test
				req := connect.NewRequest(&userv1.GetRequest{
					Name: *clientName, // 使用固定名稱而不是包含 counter
				})

				// Add request headers
				req.Header().Set("User-Agent", "connect-go-client/1.0")
				req.Header().Set("X-Client-Version", "1.0.0")

				resp, uerr := userClient.Get(reqCtx, req)
				if uerr == nil {
					message = resp.Msg.Message

					// Print all response headers
					fmt.Printf("� [%d] Response Headers:\n", counter)
					for key, values := range resp.Header() {
						for _, value := range values {
							fmt.Printf("   %s: %s\n", key, value)
						}
					}
				} else {
					err = uerr
				}
			} else {
				// Test Greeter service
				req := connect.NewRequest(&greeterv1.HelloRequest{
					Name: fmt.Sprintf("%s-%d", *clientName, counter),
				})

				// Add request headers
				req.Header().Set("User-Agent", "connect-go-client/1.0")
				req.Header().Set("X-Client-Version", "1.0.0")

				resp, gerr := greeterClient.SayHello(reqCtx, req)
				if gerr == nil {
					message = resp.Msg.Message
				} else {
					err = gerr
				}
			}

			duration := time.Since(start)
			reqCancel()

			if err != nil {
				failureCount++
				log.Printf("❌ [%d] Call failed (%v): %v", counter, duration, err)
				continue
			}

			successCount++
			fmt.Printf("✅ [%d] Response (%v): %s\n", counter, duration, message)
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
