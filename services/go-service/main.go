package main

import (
    "encoding/json"
    "io"
    "net/http"
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()
    
    // 创建一个路由组，所有路由都将以/go为前缀
    goGroup := r.Group("/go")
    
    // 根路径处理，实际访问路径为/go/
    goGroup.GET("/", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "Hello from Go Gin, root path"})
    })
    
    // 保留原来的根路径处理，用于直接访问
    r.GET("/", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "Hello from Go Gin, direct root path"})
    })
    // Call Python service endpoint
    goGroup.GET("/call-python", func(c *gin.Context) {
        resp, err := http.Get("http://python-service:80/")
        if err != nil {
            c.JSON(500, gin.H{"error": "Failed to call Python service", "details": err.Error()})
            return
        }
        defer resp.Body.Close()

        body, err := io.ReadAll(resp.Body)
        if err != nil {
            c.JSON(500, gin.H{"error": "Failed to read Python service response", "details": err.Error()})
            return
        }

        var result map[string]interface{}
        if err := json.Unmarshal(body, &result); err != nil {
            c.JSON(500, gin.H{"error": "Failed to parse Python service response", "details": err.Error()})
            return
        }
        
        c.JSON(200, gin.H{"python-service response": result})
    })
    r.Run(":8080")
}
