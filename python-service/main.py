from fastapi import FastAPI
import httpx

app = FastAPI()

@app.get("/")
async def root():
    return {"message": "Hello from Python FastAPI"}

@app.get("/call-go")
async def call_go():
    async with httpx.AsyncClient() as client:
        r = await client.get("http://go-service:8080/")
        return {"go-response": r.json()}
