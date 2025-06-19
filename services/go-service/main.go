package main

import (
    "encoding/json"
    "io"
    "net/http"
    "os"
    "github.com/gin-gonic/gin"
    "github.com/joho/godotenv"
)

func main() {
    r := gin.Default()

    // 尝试加载.env文件，如果失败则忽略（适用于Kubernetes环境）
    err := godotenv.Load()
    if err != nil {
        // 在Kubernetes环境中，这是正常的，因为配置通过环境变量传递
        // 不需要panic，只需要记录日志或忽略
        // log.Println("No .env file found, using environment variables")
    }

    // 从环境变量读取配置
    dbUser := os.Getenv("DB_USER")
    if dbUser == "" {
        panic("DB_USER environment variable not set")
    }
    dbPass := os.Getenv("DB_PASS")
    if dbPass == "" {
        panic("DB_PASS environment variable not set")
    }
    apiEndpoint := os.Getenv("API_ENDPOINT")
    if apiEndpoint == "" {
        panic("API_ENDPOINT environment variable not set")
    }
    featureFlag := os.Getenv("FEATURE_FLAG")
    if featureFlag == "" {
        panic("FEATURE_FLAG environment variable not set")
    }
    
    // 创建一个路由组，所有路由都将以/go为前缀
    goGroup := r.Group("/go")
    
    // 根路径处理，实际访问路径为/go/
    goGroup.GET("/", func(c *gin.Context) {
        hostname, _ := os.Hostname()
        
        c.JSON(200, gin.H{
            "message": "Hello from Go Gin, root path",
            "host_info": gin.H{
                "hostname":    hostname,
                "node_name":   os.Getenv("K8S_NODE_NAME"),  // Kubernetes节点名
                "pod_name":    os.Getenv("HOSTNAME"),      // Pod名称
                "pod_ip":      os.Getenv("POD_IP"),        // Pod IP
            },
            "env_vars": gin.H{
                "DB_USER":     dbUser,
                "DB_PASSWORD": dbPass,
                "API_ENDPOINT": apiEndpoint,
                "FEATURE_FLAG": featureFlag,
            },
        })
    })
    
    // 保留原来的根路径处理，用于直接访问
    r.GET("/", func(c *gin.Context) {
        hostname, _ := os.Hostname()
        c.JSON(200, gin.H{
            "message": "Hello from Go Gin, directly root path",
            "host_info": gin.H{
                "hostname":    hostname,
                "node_name":   os.Getenv("K8S_NODE_NAME"),  // Kubernetes节点名
                "pod_name":    os.Getenv("HOSTNAME"),      // Pod名称
                "pod_ip":      os.Getenv("POD_IP"),        // Pod IP
            },
            "env_vars": gin.H{
                "DB_PASSWORD": dbPass,
            },
        })
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
