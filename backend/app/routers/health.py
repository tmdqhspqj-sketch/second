from fastapi import APIRouter

from app.schemas import HealthResponse
from app.services.ollama_service import check_ollama
from app.services.rag_service import check_database
from app.config import settings

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse)
async def health() -> HealthResponse:
    ollama_ok = await check_ollama()
    database_ok = check_database()
    status = "ok" if ollama_ok and database_ok else "degraded"

    return HealthResponse(
        status=status,
        ollama=ollama_ok,
        database=database_ok,
        ollama_url=settings.ollama_base_url,
    )
