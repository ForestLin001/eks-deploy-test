from fastapi import FastAPI, Request
import httpx

# 创建应用时设置前缀
app = FastAPI(root_path="/python")

@app.get("/")
async def root():
    return {"message": "Hello from Python FastAPI, root path"}

# 添加/python路径处理
# @app.get("/python")
# async def python_root():
#     return {"message": "Hello from Python FastAPI, python path"}

@app.get("/call-go")
async def call_go():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://go-service:80/")
        return {"go-service response": r.json()}
