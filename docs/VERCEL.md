# Vercel 연결 (second 프로젝트)

## 프로젝트 정보

| 항목 | URL |
|------|-----|
| GitHub | https://github.com/tmdqhspqj-sketch/second |
| Vercel 대시보드 | https://vercel.com/hong-seung-bo-s-projects/second |

Vercel 프로젝트는 생성되어 있지만, **Git 저장소가 아직 연결되지 않은 상태**입니다.

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
   | `NEXT_PUBLIC_API_URL` | `http://localhost:8000` (임시) | Production, Preview, Development |

   > 백엔드를 공개 URL(ngrok/Railway 등)로 배포한 뒤 이 값을 교체하세요.

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
