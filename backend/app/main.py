from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.routers import chat, documents, health, models, personas

app = FastAPI(
    title="Local LLM Agent API",
    description="Ollama + RAG MVP backend",
    version="0.1.0",
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(health.router)
app.include_router(models.router)
app.include_router(personas.router)
app.include_router(chat.router)
app.include_router(documents.router)


@app.get("/")
async def root() -> dict[str, str]:
    return {"message": "Local LLM Agent API", "docs": "/docs"}
