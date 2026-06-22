# 자동 배포 워크플로

## 흐름

```
코드 수정 (Cursor/에이전트)
    ↓
에이전트 종료 시 Cursor hook → git commit + push
    ↓
GitHub (tmdqhspqj-sketch/second)
    ↓
Vercel 자동 빌드·재배포 (frontend/)
    ↓
백엔드는 로컬 또는 별도 호스트 (Ollama 필요)
```

## 1. Git 자동 push

### Cursor hook (에이전트 작업 후)

- 설정: `.cursor/hooks.json`
- 스크립트: `.cursor/hooks/auto-git-push.ps1`
- **에이전트 세션이 끝날 때** 변경 파일을 commit + push

Cursor **Hooks** 탭에서 활성화 여부를 확인하세요. 안 되면 Cursor 재시작.

### 수동 commit 후 push (선택)

```powershell
.\scripts\install-git-hooks.ps1
```

→ `git commit` 할 때마다 `git push`가 백그라운드로 실행됩니다.

## 2. Vercel 자동 재배포

GitHub push만으로 재배포됩니다. **한 번만** 연결하면 됩니다.

1. https://vercel.com/hong-seung-bo-s-projects/second/settings/git
2. **Connect Git Repository** → `tmdqhspqj-sketch/second`
3. **Root Directory**: `frontend`
4. **Environment Variables**:
   - `NEXT_PUBLIC_API_URL` = 백엔드 URL
   - `NEXT_PUBLIC_SUPABASE_URL` = `https://oglrabxukdfirjuneogx.supabase.co`

이후 `main`에 push할 때마다 Vercel이 자동 배포합니다.

## 3. Supabase (RAG 벡터 DB)

| 항목 | 값 |
|------|-----|
| Project | `tmdqhspqj-sketch's Project` |
| Ref | `oglrabxukdfirjuneogx` |
| URL | https://oglrabxukdfirjuneogx.supabase.co |
| 테이블 | `public.document_chunks` (pgvector) |

### 로컬 백엔드 env (`backend/.env`)

```env
DATABASE_URL=postgresql://postgres.[비밀번호]@db.oglrabxukdfirjuneogx.supabase.co:5432/postgres
```

Supabase Dashboard → **Settings → Database → Connection string → URI**

## 4. 주의

- **Vercel**에는 프론트만 배포됩니다. RAG/LLM API는 로컬 백엔드가 필요합니다.
- `backend/.env`의 DB 비밀번호는 Git에 올리지 마세요.
- Cursor hook은 **에이전트 세션 종료 시** 동작합니다. IDE에서만 직접 수정한 파일은 수동 commit/push가 필요할 수 있습니다.
