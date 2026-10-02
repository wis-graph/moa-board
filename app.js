// 모든 페이지가 같이 쓰는 함수 모음

const isConfigured = Boolean(SUPABASE_URL && SUPABASE_KEY);
const db = isConfigured && window.supabase
  ? window.supabase.createClient(SUPABASE_URL, SUPABASE_KEY)
  : null;

// 카드 색: CSS 클래스 이름 → 화면에 보이는 이름
const CARD_COLORS = {
  butter: "노랑", peach: "살구", mint: "민트",
  sky: "하늘", lilac: "라벤더", paper: "흰색",
};

// 태그를 만든다. 글자는 textContent로 넣어서 HTML로 해석되지 않게 한다.
function el(tag, className, text) {
  const node = document.createElement(tag);
  if (className) node.className = className;
  if (text != null) node.textContent = text;
  return node;
}

function toast(message) {
  let box = document.querySelector(".toast");
  if (!box) box = document.body.appendChild(el("div", "toast"));
  box.textContent = message;
  box.classList.add("show");
  clearTimeout(toast.timer);
  toast.timer = setTimeout(() => box.classList.remove("show"), 2600);
}

// config.js가 비어 있으면 화면 맨 위에 안내를 띄운다
function showSetupNotice() {
  if (db) return;
  const bar = el("div", "setup-notice");
  if (!isConfigured) {
    bar.append(el("strong", null, "아직 Supabase를 연결하지 않았습니다"), " — ",
      el("code", null, "config.js"), " 두 줄을 채우세요");
  } else {
    bar.append(el("strong", null, "Supabase 라이브러리를 불러오지 못했습니다"), " — 인터넷 연결을 확인하세요");
  }
  document.body.prepend(bar);
}
showSetupNotice();

async function currentUser() {
  if (!db) return null;
  const { data } = await db.auth.getSession();
  return data.session?.user ?? null;
}

function boardLink(id) {
  return new URL("board.html?id=" + id, location.href).href;
}

async function copyText(text) {
  try {
    await navigator.clipboard.writeText(text);
    toast("링크를 복사했습니다");
  } catch {
    prompt("아래 링크를 복사하세요", text);
  }
}

function timeAgo(iso) {
  const sec = Math.round((new Date(iso) - Date.now()) / 1000);
  const rtf = new Intl.RelativeTimeFormat("ko", { numeric: "auto" });
  for (const [unit, size] of [["day", 86400], ["hour", 3600], ["minute", 60]]) {
    if (Math.abs(sec) >= size) return rtf.format(Math.round(sec / size), unit);
  }
  return "방금";
}
