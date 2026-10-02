# 모아보드 (MOA BOARD) — 함께 붙이는 카드 보드

보드 주인이 보드를 만들고 링크를 나눠 주면, 링크를 받은 사람은 로그인 없이 카드(이름·내용·사진·색)를 붙입니다. 붙인 카드는 보드를 열어 둔 모든 화면에 새로고침 없이 나타납니다.

## 파일

| 파일 | 하는 일 |
|---|---|
| `index.html` | 첫 화면. 소개와 「보드 만들기」 버튼 |
| `login.html` | 이메일·비밀번호로 가입하고 로그인 |
| `dashboard.html` | 로그인한 사람의 보드 목록, 새 보드 만들기, 링크 복사, 로그아웃 |
| `board.html?id=보드id` | 보드 화면. 누구나 카드를 보고 붙인다. 보드 주인은 카드를 지운다 |
| `config.js` | Supabase 주소와 키 두 줄. **학습자가 고치는 파일은 이것 하나** |
| `app.js` | 모든 페이지가 같이 쓰는 함수 (Supabase 연결, 알림, 시간 표시) |
| `style.css` | 모든 페이지의 디자인. 색과 글꼴은 맨 위 `:root`에서 바꾼다 |
| `schema.sql` | Supabase에 표·권한·사진 저장소·실시간을 한 번에 만드는 SQL |

## 실행 순서

1. **schema.sql 실행** — Supabase 프로젝트를 만들고, SQL Editor에 `schema.sql` 전체를 붙여 넣고 Run.
   수업에서는 Authentication → Sign In / Providers → Email의 **Confirm email을 끈다**. 켜 두면 가입 직후 확인 메일을 눌러야 로그인할 수 있다(로그인 화면이 그 안내를 띄운다).
2. **config.js 채우기** — Project Settings → API Keys에서 Project URL과 publishable key(`sb_publishable_…`)를 복사해 두 줄에 넣는다. secret key는 넣지 않는다.
3. **배포** — 이 폴더를 그대로 Cloudflare Pages에 올린다. 빌드 명령은 없다.
   로컬에서 먼저 보려면 이 폴더에서 `python3 -m http.server 8000` 을 실행하고 `http://localhost:8000` 을 연다.

config.js가 비어 있어도 화면은 열린다. 모든 페이지 맨 위에 「아직 Supabase를 연결하지 않았습니다」 띠가 뜨고, 보드 화면은 견본 카드를 보여 준다.

## 일부러 넣지 않은 것 (수업에서 직접 붙인다)

- PWA — `manifest.json`, 서비스 워커 (홈 화면에 앱처럼 설치)
- Microsoft Clarity — 방문자가 어떻게 쓰는지 기록
- Sentry — 화면에서 난 오류 수집
- `sitemap.xml`, `robots.txt` — 검색 엔진 등록

## 알아 둘 한계

- 사진과 카드는 로그인 없이 누구나 올릴 수 있고 횟수 제한이 없다. 실제로 공개하기 전에 보드별 업로드 횟수 제한을 붙인다.
- 보드 화면은 최근 카드 300장만 불러온다.
