from fastapi import FastAPI, Request
import socket
import os
import httpx

# 创建应用时设置前缀
app = FastAPI(root_path="/python")

@app.get("/")
async def root():
    # 获取主机名和IP地址
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    return {
        "message": "Hello from Python FastAPI, root path",
        "host_info": {
            "hostname": hostname,
            "ip_address": ip_address,
            "node_name": os.getenv("K8S_NODE_NAME", "unknown"),  # Kubernetes节点名
            "pod_name": os.getenv("HOSTNAME", "unknown")  # Pod名称
        }
    }

# 添加/python路径处理
# @app.get("/python")
# async def python_root():
#     return {"message": "Hello from Python FastAPI, python path"}

@app.get("/call-go")
async def call_go():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://go-service:80/")
        return {"go-service response": r.json()}
