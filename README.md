# Local LLM Agent MVP

Ollama 로컬 LLM + RAG 기반 AI 에이전트 MVP입니다.

## 기술 스택

| 영역 | 기술 |
|------|------|
| LLM | Ollama (`qwen3:8b`) |
| 임베딩 | `nomic-embed-text` |
| 벡터 DB | ChromaDB |
| 백엔드 | FastAPI + LangChain |
| 프론트 | Next.js (App Router) + TypeScript |
| 페르소나 | YAML (`personas/`) |

## 사전 준비

- **Ollama** — [ollama.com/download](https://ollama.com/) (이미 설치됨)
- **Python 3.11+**
- **Node.js 18+**

이 PC에 이미 있는 모델을 사용합니다 (추가 다운로드 불필요):

| 역할 | 모델 |
|------|------|
| LLM | `local-agent:latest` |
| 임베딩 | `embeddinggemma:latest` |

## 한 번에 설치·실행 (Windows)

```powershell
cd C:\Repo\second
.\setup.ps1    # 최초 1회
.\start.ps1    # 백엔드 + 프론트 실행
```

브라우저: http://localhost:3000

## 수동 실행

### Ollama

Ollama 앱을 켜 두면 됩니다. 모델이 없을 때만:

```powershell
ollama pull gemma4:e4b
ollama pull embeddinggemma
```

## 빠른 RAG 테스트

1. 백엔드·프론트·Ollama 실행
2. 프론트에서 `backend/data/samples/project-info.md` 업로드
3. 질문: "이 프로젝트의 기술 스택은?"

## API

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/health` | Ollama·Chroma 상태 |
| GET | `/models` | Ollama 모델 목록 |
| GET | `/personas` | 페르소나 목록 |
| POST | `/chat` | RAG 채팅 |
| POST | `/documents` | 문서 업로드·인덱싱 |

## 페르소나

`personas/default.yaml`, `personas/formal.yaml` 파일을 수정하면 응답 톤을 변경할 수 있습니다.

## Post-MVP (예정)

- LangGraph 에이전트 그래프
- FastMCP 툴 연동
- SSE 스트리밍

## 디렉터리 구조

```
second/
├── backend/          # FastAPI + RAG
├── frontend/         # Next.js
├── personas/         # 페르소나 YAML
├── PRD.md
└── README.md
```
