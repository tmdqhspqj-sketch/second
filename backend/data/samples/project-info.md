# 샘플 문서 (RAG 테스트용)

이 프로젝트는 Ollama 로컬 LLM과 RAG를 사용하는 AI 에이전트 MVP입니다.

## 기술 스택
- LLM: Ollama (`local-agent:latest`)
- 임베딩: `embeddinggemma:latest`
- 벡터 DB: ChromaDB
- 백엔드: FastAPI
- 프론트엔드: Next.js

## MVP 목표
1. 문서 업로드 후 RAG 기반 질의응답
2. 페르소나 YAML로 응답 톤 변경
3. Next.js 채팅 UI에서 end-to-end 테스트

## Post-MVP
LangGraph와 FastMCP를 연동하여 툴 호출 에이전트로 확장합니다.
