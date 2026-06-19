from fastapi import APIRouter, HTTPException

from app.schemas import ModelInfo
from app.services.ollama_service import check_ollama, list_models

router = APIRouter(tags=["models"])


@router.get("/models", response_model=list[ModelInfo])
async def get_models() -> list[ModelInfo]:
    if not await check_ollama():
        raise HTTPException(status_code=503, detail="Ollama is not reachable")

    raw_models = await list_models()
    return [
        ModelInfo(
            name=item.get("name", ""),
            size=item.get("size"),
            modified_at=item.get("modified_at"),
        )
        for item in raw_models
    ]
