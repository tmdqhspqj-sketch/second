from fastapi import APIRouter, File, HTTPException, UploadFile

from app.config import settings
from app.schemas import DocumentUploadResponse
from app.services.rag_service import index_file

router = APIRouter(tags=["documents"])


@router.post("/documents", response_model=DocumentUploadResponse)
async def upload_document(file: UploadFile = File(...)) -> DocumentUploadResponse:
    filename = file.filename or "upload.txt"
    suffix = filename.lower().split(".")[-1] if "." in filename else ""
    if suffix not in {"txt", "md"}:
        raise HTTPException(status_code=400, detail="MVP supports .txt and .md files only")

    dest = settings.upload_dir / filename
    content = await file.read()
    dest.write_bytes(content)

    try:
        chunks = index_file(dest)
    except Exception as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    return DocumentUploadResponse(
        filename=filename,
        chunks_indexed=chunks,
        message=f"{chunks}개 청크가 인덱싱되었습니다.",
    )
