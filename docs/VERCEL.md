# Vercel 연결 (second 프로젝트)

## 프로젝트 정보

| 항목 | URL |
|------|-----|
| GitHub | https://github.com/tmdqhspqj-sketch/second |
| Vercel 배포 URL | https://second-jalspejz3-hong-seung-bo-s-projects.vercel.app |

---

## 1. GitHub push (로컬 → GitHub)

로컬에서 한 번만 실행:

```powershell
cd C:\Repo\second
git init
git add .
git commit -m "Initial commit: local LLM agent MVP"
git branch -M main
git remote add origin https://github.com/tmdqhspqj-sketch/second.git
git push -u origin main
```

이미 `remote origin`이 있으면:

```powershell
git remote set-url origin https://github.com/tmdqhspqj-sketch/second.git
git push -u origin main
```

---

## 2. Vercel에서 Git 연결 (대시보드)

1. https://vercel.com/hong-seung-bo-s-projects/second/settings/git 열기  
   (또는 프로젝트 → **Settings** → **Git**)

2. **Connect Git Repository** 클릭

3. GitHub 계정 연동 후 **`tmdqhspqj-sketch/second`** 선택

4. **Settings → General** 에서 확인:

   | 설정 | 값 |
   |------|-----|
   | Root Directory | `frontend` |
   | Framework | Next.js |
   | Build Command | `npm run build` |
   | Install Command | `npm install` |

5. **Settings → Environment Variables** 추가:

   | Name | Value | Environment |
   |------|-------|-------------|
   | `NEXT_PUBLIC_API_URL` | 백엔드 공개 URL (아래 참고) | Production, Preview, Development |
   | `NEXT_PUBLIC_SUPABASE_URL` | `https://oglrabxukdfirjuneogx.supabase.co` | Production, Preview, Development |

   > `NEXT_PUBLIC_API_URL`에 Vercel URL(`second-...vercel.app`)을 넣으면 **안 됩니다.**  
   > 프론트(Vercel)가 호출할 **FastAPI 백엔드 주소**를 넣어야 합니다.

6. **Deployments** → **Redeploy** (또는 main에 push하면 자동 배포)

---

## 3. 배포 후 확인

- Production URL: Vercel **Domains** 탭에서 확인 (예: `second-xxx.vercel.app`)
- 채팅이 동작하려면 `NEXT_PUBLIC_API_URL`이 **실제 백엔드 주소**를 가리켜야 합니다.

---

## 4. 자동 배포 흐름 (연결 후)

```
git push origin main  →  GitHub  →  Vercel 자동 빌드·배포 (frontend/)
```

백엔드(`backend/`)는 Vercel에 배포되지 않습니다. 로컬 또는 Railway 등 별도 호스트 필요.
