from fastapi import APIRouter, HTTPException

from app.schemas import PersonaDetail, PersonaSummary
from app.services.persona_service import get_persona, list_personas

router = APIRouter(tags=["personas"])


@router.get("/personas", response_model=list[PersonaSummary])
async def get_personas() -> list[PersonaSummary]:
    personas = list_personas()
    return [
        PersonaSummary(
            id=p.id,
            name=p.name,
            model_id=p.model_id,
            temperature=p.temperature,
        )
        for p in personas
    ]


@router.get("/personas/{persona_id}", response_model=PersonaDetail)
async def get_persona_detail(persona_id: str) -> PersonaDetail:
    try:
        persona = get_persona(persona_id)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc

    return PersonaDetail(
        id=persona.id,
        name=persona.name,
        model_id=persona.model_id,
        temperature=persona.temperature,
        system_prompt=persona.system_prompt,
        tools_allowed=persona.tools_allowed,
    )
