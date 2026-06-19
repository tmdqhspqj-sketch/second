from pathlib import Path

from langchain_community.document_loaders import TextLoader
from langchain_community.vectorstores import Chroma
from langchain_ollama import ChatOllama, OllamaEmbeddings
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from langchain_core.prompts import ChatPromptTemplate

from app.config import settings
from app.services.persona_service import Persona


COLLECTION_NAME = "documents"


def _get_embeddings() -> OllamaEmbeddings:
    return OllamaEmbeddings(
        model=settings.embedding_model,
        base_url=settings.ollama_base_url,
    )


def _get_vectorstore() -> Chroma:
    return Chroma(
        collection_name=COLLECTION_NAME,
        embedding_function=_get_embeddings(),
        persist_directory=str(settings.chroma_dir),
    )


def check_chroma() -> bool:
    try:
        _get_vectorstore()
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

    vectorstore = _get_vectorstore()
    vectorstore.add_documents(chunks)
    return len(chunks)


def retrieve_context(query: str) -> tuple[str, list[str]]:
    vectorstore = _get_vectorstore()
    results = vectorstore.similarity_search(query, k=settings.top_k)

    if not results:
        return "", []

    context_parts: list[str] = []
    sources: list[str] = []
    for index, doc in enumerate(results, start=1):
        source = doc.metadata.get("source", "unknown")
        sources.append(source)
        context_parts.append(f"[{index}] ({source})\n{doc.page_content}")

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
