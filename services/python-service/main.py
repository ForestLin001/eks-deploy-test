from fastapi import FastAPI, Request
import socket
import os
import httpx
from dotenv import load_dotenv

# 创建应用时设置前缀
app = FastAPI(root_path="/python")
load_dotenv()

@app.get("/")
async def root():
    # 获取主机名和IP地址
    hostname = socket.gethostname()
    ip_address = socket.gethostbyname(hostname)
    
    db_user = os.getenv("DB_USER")
    print(f"Loaded DB_USER: {db_user}")
    db_pass = os.getenv("DB_PASS")
    print(f"Loaded DB_PASS: {db_pass}")
    api_endpoint = os.getenv("API_ENDPOINT")
    print(f"Loaded API_ENDPOINT: {api_endpoint}")
    feature_flag = os.getenv("FEATURE_FLAG")
    print(f"Loaded FEATURE_FLAG: {feature_flag}")

    return {
        "message": "Hello from Python FastAPI, root path",
        "host_info": {
            "hostname": hostname,
            "ip_address": ip_address,
            "node_name": os.getenv("K8S_NODE_NAME", "unknown"),  # Kubernetes节点名
            "pod_name": os.getenv("HOSTNAME", "unknown")  # Pod名称
        },
        "env_vars": {
            "DB_USER": db_user,
            "DB_PASSWORD": db_pass,
            "API_ENDPOINT": api_endpoint,
            "FEATURE_FLAG": feature_flag
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
