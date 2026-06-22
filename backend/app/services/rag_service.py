import json
from pathlib import Path

import psycopg
from langchain_community.document_loaders import TextLoader
from langchain_ollama import ChatOllama, OllamaEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate
from pgvector.psycopg import register_vector

from app.config import settings
from app.services.persona_service import Persona


def _get_embeddings() -> OllamaEmbeddings:
    return OllamaEmbeddings(
        model=settings.embedding_model,
        base_url=settings.ollama_base_url,
    )


def _require_database_url() -> str:
    if not settings.database_url:
        raise RuntimeError(
            "DATABASE_URL is not set. Add your Supabase Postgres URL to backend/.env"
        )
    return settings.database_url


def check_database() -> bool:
    if not settings.database_url:
        return False
    try:
        with psycopg.connect(settings.database_url) as conn:
            with conn.cursor() as cur:
                cur.execute("select 1")
        return True
    except Exception:
        return False


def _split_documents(documents: list[Document]) -> list[Document]:
    splitter = RecursiveCharacterTextSplitter(
        chunk_size=settings.chunk_size,
        chunk_overlap=settings.chunk_overlap,
    )
    return splitter.split_documents(documents)


def index_file(file_path: Path) -> int:
    suffix = file_path.suffix.lower()
    if suffix not in {".txt", ".md"}:
        raise ValueError("MVP supports .txt and .md files only")

    loader = TextLoader(str(file_path), encoding="utf-8")
    documents = loader.load()
    for doc in documents:
        doc.metadata["source"] = file_path.name

    chunks = _split_documents(documents)
    if not chunks:
        return 0

    embeddings = _get_embeddings()
    texts = [chunk.page_content for chunk in chunks]
    vectors = embeddings.embed_documents(texts)

    with psycopg.connect(_require_database_url()) as conn:
        register_vector(conn)
        with conn.cursor() as cur:
            for chunk, vector in zip(chunks, vectors):
                cur.execute(
                    """
                    insert into public.document_chunks (content, metadata, embedding)
                    values (%s, %s::jsonb, %s)
                    """,
                    (chunk.page_content, json.dumps(chunk.metadata), vector),
                )
        conn.commit()

    return len(chunks)


def retrieve_context(query: str) -> tuple[str, list[str]]:
    embeddings = _get_embeddings()
    query_vector = embeddings.embed_query(query)

    with psycopg.connect(_require_database_url()) as conn:
        register_vector(conn)
        with conn.cursor() as cur:
            cur.execute(
                """
                select content, metadata->>'source' as source
                from public.document_chunks
                order by embedding <=> %s
                limit %s
                """,
                (query_vector, settings.top_k),
            )
            rows = cur.fetchall()

    if not rows:
        return "", []

    context_parts: list[str] = []
    sources: list[str] = []
    for index, (content, source) in enumerate(rows, start=1):
        source_name = source or "unknown"
        sources.append(source_name)
        context_parts.append(f"[{index}] ({source_name})\n{content}")

    return "\n\n".join(context_parts), list(dict.fromkeys(sources))


def chat_with_rag(persona: Persona, message: str, use_rag: bool) -> tuple[str, list[str]]:
    context = ""
    sources: list[str] = []

    if use_rag:
        context, sources = retrieve_context(message)

    system_prompt = persona.system_prompt
    if context:
        system_prompt += (
            "\n\n아래는 검색된 참고 문서입니다. 답변 시 이 내용을 근거로 활용하세요.\n\n"
            f"{context}"
        )
    else:
        system_prompt += "\n\n참고 문서가 없습니다. 일반 지식으로 답하되, 확실하지 않으면 모른다고 하세요."

    prompt = ChatPromptTemplate.from_messages(
        [
            ("system", system_prompt),
            ("human", "{message}"),
        ]
    )

    llm = ChatOllama(
        model=persona.model_id,
        base_url=settings.ollama_base_url,
        temperature=persona.temperature,
    )

    chain = prompt | llm
    response = chain.invoke({"message": message})
    answer = response.content if hasattr(response, "content") else str(response)
    return answer, sources
