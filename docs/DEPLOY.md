# Git · Vercel · Supabase 연결 가이드

## 1. 구현 완료 여부

| 구분 | 상태 |
|------|------|
| **로컬 MVP** (Ollama + RAG + FastAPI + Next.js) | ✅ 완료 |
| **Git / Vercel / Supabase 연결** | ❌ 아직 안 함 (이 문서대로 진행) |
| **LangGraph + FastMCP** (Post-MVP) | ❌ 미구현 |

로컬에서 `.\start.ps1`로 돌리는 MVP는 끝났고, **클라우드 배포·DB 연동은 다음 단계**입니다.

---

## 2. 배포 구조 (중요)

Ollama는 **Vercel에서 실행할 수 없습니다.** 역할을 나눠야 합니다.

```mermaid
flowchart LR
  User[브라우저] --> Vercel[Vercel\nNext.js 프론트]
  Vercel --> API[백엔드 FastAPI\nRailway / Render / VPS]
  API --> Ollama[Ollama\n로컬 PC 또는 GPU 서버]
  API --> Supabase[(Supabase\nPostgres + pgvector)]
  Vercel --> Supabase
```

| 서비스 | 역할 | 이 프로젝트에서 |
|--------|------|----------------|
| **GitHub** | 코드 저장, CI/CD 트리거 | monorepo (`frontend/` + `backend/`) |
| **Vercel** | Next.js UI 호스팅 | `frontend/`만 배포 |
| **Supabase** | DB, Auth, 벡터(pgvector), Storage | ChromaDB 대체, 채팅/문서 저장 |
| **백엔드 호스트** | FastAPI + Ollama 연동 | Vercel **불가** → Railway/Render/VPS 등 |

---

## 3. Git 연결 (GitHub)

### 3-1. 로컬 Git 초기화

```powershell
cd C:\Repo\second
git init
git add .
git commit -m "Initial commit: local LLM agent MVP"
```

### 3-2. GitHub 저장소 생성 후 push

1. https://github.com/new 에서 저장소 생성 (예: `local-llm-agent`)
2. 아래 실행:

```powershell
git branch -M main
git remote add origin https://github.com/<YOUR_USER>/local-llm-agent.git
git push -u origin main
```

`.env`, `.env.local`, `backend/.venv/` 등은 `.gitignore`에 포함되어 있어 push되지 않습니다.

---

## 4. Vercel 연결 (프론트엔드)

### 4-1. Vercel 대시보드

1. https://vercel.com → **Add New Project**
2. GitHub 저장소 import
3. **Root Directory** → `frontend` 로 설정
4. Environment Variables 추가:

| Name | Value | 비고 |
|------|-------|------|
| `NEXT_PUBLIC_API_URL` | `https://your-api.railway.app` | 백엔드 공개 URL |

5. Deploy

### 4-2. 주의

- Vercel만 배포하면 **API가 localhost:8000** 이라 프로덕션에서 채팅이 동작하지 않습니다.
- **백엔드를 먼저 공개 URL로 배포**한 뒤, 그 URL을 `NEXT_PUBLIC_API_URL`에 넣어야 합니다.
- Ollama가 로컬 PC에만 있으면, 백엔드도 **같은 PC/VPN/터널**에서 접근 가능해야 합니다.

### 4-3. 백엔드 배포 옵션 (FastAPI)

| 플랫폼 | Ollama | 추천 |
|--------|--------|------|
| **로컬 PC + ngrok/Cloudflare Tunnel** | ✅ 같은 PC | 개발·데모용 가장 쉬움 |
| **Railway / Render / Fly.io** | ❌ 별도 GPU 서버 필요 | Ollama URL을 env로 연결 |
| **자체 VPS (GPU)** | ✅ | 프로덕션에 가까움 |

---

## 5. Supabase 연결

### 5-1. Supabase 프로젝트 생성

1. https://supabase.com/dashboard → **New project**
2. 프로젝트 URL, **anon key**, **service_role key** 확인 (Settings → API)

### 5-2. Supabase로 대체할 것 (권장 순서)

| 현재 (로컬) | Supabase |
|-------------|----------|
| ChromaDB | **pgvector** (문서 임베딩) |
| YAML 페르소나 | `personas` 테이블 (선택) |
| 업로드 파일 | **Storage** 버킷 |
| (없음) | **Auth** 로그인 (선택) |

MVP 코드는 아직 ChromaDB입니다. Supabase 연동은 **코드 수정 + 마이그레이션**이 필요합니다.

### 5-3. pgvector 활성화 (SQL)

Supabase Dashboard → **SQL Editor**에서 실행:

```sql
create extension if not exists vector;

create table if not exists document_chunks (
  id bigserial primary key,
  content text not null,
  metadata jsonb default '{}',
  embedding vector(768),
  created_at timestamptz default now()
);

create index on document_chunks
  using hnsw (embedding vector_cosine_ops);
```

임베딩 차원(768 등)은 사용하는 모델(`embeddinggemma`)에 맞게 조정해야 합니다.

### 5-4. 환경 변수

**백엔드** (`backend/.env`):

```env
SUPABASE_URL=https://xxxx.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...   # 서버 전용, Git에 올리지 말 것
DATABASE_URL=postgresql://postgres:...@db.xxxx.supabase.co:5432/postgres
```

**프론트** (Vercel Environment Variables):

```env
NEXT_PUBLIC_SUPABASE_URL=https://xxxx.supabase.co
NEXT_PUBLIC_SUPABASE_ANON_KEY=eyJ...
NEXT_PUBLIC_API_URL=https://your-api.example.com
```

- `service_role` / `DATABASE_URL` → **백엔드만**
- `anon` key → **프론트만** (RLS 필수)

### 5-5. Supabase CLI (로컬 개발, 선택)

```powershell
npm install -g supabase
supabase login
cd C:\Repo\second
supabase init
supabase link --project-ref <project-ref>
```

---

## 6. 추천 진행 순서

```
1. Git init → GitHub push
2. 백엔드를 ngrok/Railway 등으로 공개 URL 확보
3. Vercel에 frontend 배포 + NEXT_PUBLIC_API_URL 설정
4. Supabase 프로젝트 생성 → pgvector 마이그레이션
5. 백엔드 RAG를 Chroma → Supabase pgvector로 교체 (코드 작업)
6. (선택) Supabase Auth를 Next.js에 연결
```

---

## 7. 지금 당장 최소 연결 (데모용)

GitHub + Vercel만 먼저:

1. Git push
2. Vercel `frontend` 배포
3. 로컬에서 `.\start.ps1`로 백엔드 실행
4. **ngrok**으로 8000 포트 노출: `ngrok http 8000`
5. Vercel env: `NEXT_PUBLIC_API_URL=https://xxxx.ngrok-free.app`

→ UI는 Vercel, LLM/RAG는 내 PC에서 동작 (데모용).

---

## 8. 다음에 코드로 해 줄 수 있는 것

원하시면 이어서:

- [ ] Git 초기화 + 첫 commit
- [ ] Supabase 마이그레이션 파일 + pgvector RAG 교체
- [ ] Next.js Supabase Auth 연동
- [ ] Railway용 `Dockerfile` / 배포 설정

어디까지 진행할지 알려주세요.
