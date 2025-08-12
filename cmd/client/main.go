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
	serverAddr = flag.String("addr", "http://connect-go.phison.com", "服務器地址")
	interval   = flag.Duration("interval", 300*time.Millisecond, "調用間隔")
	timeout    = flag.Duration("timeout", 10*time.Second, "請求超時時間")
	clientName = flag.String("name", "TestClient", "客戶端名稱前綴")
	enableTLS  = flag.Bool("tls", false, "是否使用 HTTPS")
)

func main() {
	flag.Parse()

	// 根據 TLS 設置調整地址
	addr := *serverAddr
	if *enableTLS && !contains(addr, "https://") {
		addr = "https://" + removeProtocol(addr)
	} else if !*enableTLS && !contains(addr, "http://") {
		addr = "http://" + removeProtocol(addr)
	}

	// 創建 HTTP 客戶端
	client := &http.Client{
		Timeout: *timeout,
	}

	// 創建 Connect 客戶端
	greeterClient := greeterv1connect.NewGreeterClient(client, addr)

	// 創建可取消的上下文
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// 處理系統信號
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// 統計資訊
	var successCount, failureCount int

	// 創建 ticker
	ticker := time.NewTicker(*interval)
	defer ticker.Stop()

	fmt.Printf("🚀 開始每 %v 調用 SayHello API\n", *interval)
	fmt.Printf("📡 服務器地址: %s\n", addr)
	fmt.Printf("⏰ 超時時間: %v\n", *timeout)
	fmt.Printf("👤 客戶端名稱: %s\n", *clientName)
	fmt.Println("按 Ctrl+C 停止...")
	fmt.Println(strings.Repeat("-", 50))

	counter := 0

	for {
		select {
		case <-sigChan:
			fmt.Println("\n📊 統計資訊:")
			fmt.Printf("✅ 成功: %d 次\n", successCount)
			fmt.Printf("❌ 失敗: %d 次\n", failureCount)
			fmt.Printf("📈 成功率: %.2f%%\n", float64(successCount)/float64(successCount+failureCount)*100)
			fmt.Println("👋 再見!")
			return

		case <-ticker.C:
			counter++

			// 創建帶超時的上下文
			reqCtx, reqCancel := context.WithTimeout(ctx, *timeout)

			// 創建請求
			req := connect.NewRequest(&v1.HelloRequest{
				Name: fmt.Sprintf("%s-%d", *clientName, counter),
			})

			// 添加請求頭（可選）
			req.Header().Set("User-Agent", "connect-go-client/1.0")
			req.Header().Set("X-Client-Version", "1.0.0")

			start := time.Now()

			// 調用 API
			resp, err := greeterClient.SayHello(reqCtx, req)

			duration := time.Since(start)
			reqCancel()

			if err != nil {
				failureCount++
				log.Printf("❌ [%d] 調用失敗 (%v): %v", counter, duration, err)
				continue
			}

			successCount++
			fmt.Printf("✅ [%d] 響應 (%v): %s\n", counter, duration, resp.Msg.Message)
		}
	}
}

// 輔助函數
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
