from pydantic import BaseModel, Field


class HealthResponse(BaseModel):
    status: str
    ollama: bool
    chroma: bool
    ollama_url: str


class ModelInfo(BaseModel):
    name: str
    size: int | None = None
    modified_at: str | None = None


class PersonaSummary(BaseModel):
    id: str
    name: str
    model_id: str
    temperature: float


class PersonaDetail(PersonaSummary):
    system_prompt: str
    tools_allowed: list[str] = Field(default_factory=list)


class ChatRequest(BaseModel):
    message: str = Field(min_length=1)
    persona_id: str = "default"
    use_rag: bool = True


class ChatResponse(BaseModel):
    answer: str
    persona_id: str
    model_id: str
    sources: list[str] = Field(default_factory=list)


class DocumentUploadResponse(BaseModel):
    filename: str
    chunks_indexed: int
    message: str
