# src/backend/main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import os
import socket

app = FastAPI()

# Allow Frontend to talk to Backend (CORS)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def read_root():
    hostname = socket.gethostname()
    return {
        "message": "Hello from GKE 3-Tier App!",
        "pod_name": hostname,
        "environment": "Production"
    }

@app.get("/health")
def health_check():
    return {"status": "healthy"}