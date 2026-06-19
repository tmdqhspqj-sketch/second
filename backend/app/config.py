from pathlib import Path

from pydantic_settings import BaseSettings, SettingsConfigDict


ROOT_DIR = Path(__file__).resolve().parents[2]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    ollama_base_url: str = "http://localhost:11434"
    default_llm_model: str = "local-agent:latest"
    embedding_model: str = "embeddinggemma:latest"
    chunk_size: int = 800
    chunk_overlap: int = 150
    top_k: int = 4

    personas_dir: Path = ROOT_DIR / "personas"
    chroma_dir: Path = ROOT_DIR / "backend" / "data" / "chroma"
    upload_dir: Path = ROOT_DIR / "backend" / "data" / "uploads"

    cors_origins: list[str] = ["http://localhost:3000"]


settings = Settings()

settings.chroma_dir.mkdir(parents=True, exist_ok=True)
settings.upload_dir.mkdir(parents=True, exist_ok=True)
