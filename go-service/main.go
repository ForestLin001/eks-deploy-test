package main

import (
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
    
    r.Run(":8080")
}
