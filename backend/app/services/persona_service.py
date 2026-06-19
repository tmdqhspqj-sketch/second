from pathlib import Path

import yaml
from pydantic import BaseModel, Field

from app.config import settings


class Persona(BaseModel):
    id: str
    name: str
    model_id: str
    temperature: float = 0.3
    system_prompt: str
    tools_allowed: list[str] = Field(default_factory=list)


def _load_persona_file(path: Path) -> Persona:
    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    persona_id = data.get("id") or path.stem
    return Persona(id=persona_id, **{k: v for k, v in data.items() if k != "id"})


def list_personas() -> list[Persona]:
    personas_dir = settings.personas_dir
    if not personas_dir.exists():
        return []

    personas: list[Persona] = []
    for path in sorted(personas_dir.glob("*.yaml")):
        personas.append(_load_persona_file(path))
    return personas


def get_persona(persona_id: str) -> Persona:
    path = settings.personas_dir / f"{persona_id}.yaml"
    if not path.exists():
        raise FileNotFoundError(f"Persona not found: {persona_id}")
    return _load_persona_file(path)
