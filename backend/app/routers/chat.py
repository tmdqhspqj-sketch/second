from fastapi import APIRouter, HTTPException

from app.schemas import ChatRequest, ChatResponse
from app.services.persona_service import get_persona
from app.services.rag_service import chat_with_rag

router = APIRouter(tags=["chat"])


@router.post("/chat", response_model=ChatResponse)
async def chat(request: ChatRequest) -> ChatResponse:
    try:
        persona = get_persona(request.persona_id)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    try:
        answer, sources = chat_with_rag(
            persona=persona,
            message=request.message,
            use_rag=request.use_rag,
        )
    except Exception as exc:
        raise HTTPException(
            status_code=503,
            detail=f"LLM/RAG error: {exc}. Ollama 모델({persona.model_id})이 pull 되었는지 확인하세요.",
        ) from exc

    return ChatResponse(
        answer=answer,
        persona_id=persona.id,
        model_id=persona.model_id,
        sources=sources,
    )
