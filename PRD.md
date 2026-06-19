# PRD: 로컬 LLM 기반 AI 에이전트 (MVP)

## 1. 개요

Ollama로 로컬 LLM을 구동하고, Python 백엔드와 Next.js 프론트엔드로 AI 에이전트를 구축한다.  
MVP 단계에서는 **간단한 RAG**로 검색·응답 품질을 검증한 뒤, LangGraph 기반 에이전트 워크플로와 MCP 툴 연동을 확장한다.

## 2. 목표

| 구분 | 내용 |
|------|------|
| **1차 목표 (MVP)** | 로컬 LLM + RAG로 질의응답 동작 검증 |
| **2차 목표** | LangGraph로 툴 호출·멀티스텝 에이전트 처리 |
| **비목표 (MVP)** | 클라우드 LLM, 복잡한 멀티 에이전트 오케스트레이션 |

## 3. 기술 스택

| 영역 | 기술 | 역할 |
|------|------|------|
| LLM 런타임 | **Ollama** | 로컬 모델 풀링·추론 |
| 백엔드 API | **FastAPI** | REST API, 헬스체크, 에이전트/RAG 엔드포인트 |
| MCP 서버 | **FastMCP (Python)** | 외부·로컬 툴을 MCP 프로토콜로 노출 |
| 에이전트 오케스트레이션 | **LangGraph** | 툴 호출, 분기, 상태 관리, 멀티스텝 플로우 |
| 프론트엔드 | **Next.js** | 채팅 UI, 모델·페르소나 선택, API 연동 |
| 페르소나 설정 | **모델 파일 (YAML/JSON 등)** | 시스템 프롬프트, 톤, 도메인 지식 선언 |
| MVP 검증 | **간단한 RAG** | 문서 임베딩·검색 후 LLM 컨텍스트 주입 |

## 4. 시스템 아키텍처 (개념)

```
┌─────────────┐     HTTP/WS      ┌─────────────┐
│  Next.js    │ ◄──────────────► │  FastAPI    │
│  (Frontend) │                  │  (Backend)  │
└─────────────┘                  └──────┬──────┘
                                      │
                    ┌─────────────────┼─────────────────┐
                    ▼                 ▼                 ▼
             ┌──────────┐      ┌──────────┐      ┌──────────┐
             │  Ollama  │      │LangGraph │      │ FastMCP  │
             │ (Local   │      │ (Agent   │      │ (Tools)  │
             │  LLM)    │      │  Flow)   │      │          │
             └──────────┘      └──────────┘      └──────────┘
                                      │
                                      ▼
                              ┌──────────────┐
                              │ RAG (MVP)    │
                              │ Vector Store │
                              └──────────────┘
```

## 5. 핵심 기능

### 5.1 MVP (RAG)

- 문서 업로드 또는 고정 코퍼스 인덱싱
- 쿼리 임베딩 → 유사도 검색 → 상위 k개 청크를 프롬프트에 주입
- Ollama 모델로 답변 생성
- FastAPI로 `/chat`, `/health`, `/models` 등 기본 API 제공

### 5.2 에이전트 (LangGraph)

- 사용자 입력 → (선택) RAG 검색 → LLM 추론 → 툴 필요 시 MCP 호출 → 재추론 → 응답
- 그래프 노드: `retrieve`, `generate`, `tool_call`, `respond` 등
- 상태 객체로 대화·검색 결과·툴 결과 유지

### 5.3 MCP (FastMCP)

- Python으로 툴 정의 (파일 읽기, DB 조회, 커스텀 API 등)
- LangGraph 에이전트가 MCP 클라이언트로 툴 호출

### 5.4 페르소나 (모델 파일)

- 파일 단위로 페르소나 정의 (예: `personas/assistant.yaml`)
- 필드 예: `name`, `system_prompt`, `temperature`, `model_id`, `tools_allowed`
- Next.js에서 페르소나 선택 시 백엔드에 persona ID 전달

### 5.5 프론트엔드 (Next.js)

- 채팅 인터페이스
- Ollama 모델·페르소나 선택
- FastAPI 백엔드 연동 (스트리밍 응답 지원 권장)

## 6. API 개요 (FastAPI)

| 메서드 | 경로 | 설명 |
|--------|------|------|
| GET | `/health` | Ollama·벡터 DB 연결 상태 |
| GET | `/models` | Ollama 사용 가능 모델 목록 |
| GET | `/personas` | 페르소나 파일 목록 |
| POST | `/chat` | RAG/에이전트 대화 (MVP: RAG only) |
| POST | `/documents` | (선택) 문서 인덱싱 |

## 7. MVP 검증 기준

- [ ] Ollama 로컬 설치 및 모델 pull (`ollama pull <model>`)
- [ ] FastAPI `/health`, `/chat` 정상 응답
- [ ] RAG: 인덱스된 문서 기반 질의에 근거 있는 답변
- [ ] Next.js에서 채팅 UI로 end-to-end 테스트
- [ ] 페르소나 파일 변경 시 응답 톤·역할 반영

## 8. 이후 확장 (Post-MVP)

- LangGraph 툴 노드 + FastMCP 연동
- 대화 스트리밍 (SSE/WebSocket)
- 멀티 페르소나·세션 관리
- 평가 파이프라인 (RAGAS 등)

## 9. 디렉터리 구조 (안)

```
project/
├── backend/
│   ├── app/           # FastAPI
│   ├── agent/         # LangGraph 그래프
│   ├── mcp/           # FastMCP 서버
│   ├── rag/           # 임베딩·검색
│   └── personas/      # 페르소나 YAML/JSON
├── frontend/          # Next.js
├── docs/
│   └── PRD.md
└── docker-compose.yml # (선택) Ollama + 앱
```

## 10. 리스크·전제

- **전제**: 로컬 GPU/CPU로 Ollama 모델 실행 가능
- **리스크**: 소형 모델 RAG 품질 한계 → MVP는 “동작 검증”에 초점
- **리스크**: MCP·LangGraph 통합 복잡도 → MVP 이후 단계로 분리

---

*문서 버전: 0.1 (MVP 요약)*
