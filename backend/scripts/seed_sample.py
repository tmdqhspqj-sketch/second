"""샘플 문서를 ChromaDB에 미리 인덱싱합니다."""
from pathlib import Path

from app.config import settings
from app.services.rag_service import index_file


def main() -> None:
    sample = settings.upload_dir.parent / "samples" / "project-info.md"
    if not sample.exists():
        print(f"샘플 파일 없음: {sample}")
        return

    chunks = index_file(sample)
    print(f"인덱싱 완료: {sample.name} ({chunks} chunks)")


if __name__ == "__main__":
    main()
