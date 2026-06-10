# 02 — Self-host Docker 安裝

> 路線 B：完整自架，Docker Compose 一鍵啟動
>
> **所有終端指令都是完整的複製貼上區塊。** 不需要手動編輯任何設定檔。

---

## 適用情境

- 資料主權需求
- 企業內網部署
- 需要客製化 LLM provider
- Production self-host

## 優點

- 完全控制資料
- 可用任何 OpenAI-compatible LLM（包含 Ollama 本機模型）
- 不依賴 Honcho 雲端

## 缺點

- 需要維護 Docker 環境
- 首次 build 從 source，需要幾分鐘
- LLM API key 仍需自行提供

## 前置需求

- Docker Desktop（Windows）：https://www.docker.com/products/docker-desktop/
- Git for Windows：https://git-scm.com/download/win
- LLM API key（至少一個，預設 OpenAI）

---

## ⚠️ 重要：沒有預建 Docker Image

Honcho **沒有** 預先上傳到 Docker Hub 的 image。
`docker compose up --build` 會從 source code 編譯。
首次 build 約 3-5 分鐘，之後再啟動很快。

---

## 安裝步驟

### Step 1：Clone Repo

```powershell
git clone https://github.com/plastic-labs/honcho.git
cd honcho
```

### Step 2：準備環境變數（不需要手動開檔案）

把 `sk-你的OpenAI-Key貼這裡` 換成你的真實 OpenAI API Key，然後複製整個區塊貼上：

```powershell
@"
# LLM Provider（至少設定一個）
LLM_OPENAI_API_KEY=sk-你的OpenAI-Key貼這裡

# 資料庫
DATABASE_URI=postgresql+psycopg://honcho:honcho@database:5432/honcho

# Redis
REDIS_URL=redis://redis:6379/0

# 認證（開發用關閉，上線前開啟）
AUTH_USE_AUTH=false

# Log
LOG_LEVEL=INFO
"@ | Out-File -FilePath ".env" -Encoding utf8
```

確認檔案建立成功：

```powershell
Get-Content .env
```

**看到設定內容顯示出來** → 繼續。

### Step 3：準備 docker-compose.yml

```powershell
Copy-Item docker-compose.yml.example docker-compose.yml
```

### Step 4：啟動所有 service

```powershell
docker compose up -d --build
```

第一次會從 source build，需要 3-5 分鐘。

### Step 5：確認所有 container 啟動

```powershell
docker compose ps
```

應該看到四個 service 都在 running 狀態：
- `api`（port 8000）
- `deriver`
- `database`（port 5432）
- `redis`（port 6379）

### Step 6：Health check

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/health"
# 預期回應：{"status":"ok"}
```

### Step 7：確認資料庫連線（完整驗證）

```powershell
Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name": "test"}'
```

若取回 workspace 物件（含 `id` 欄位），代表 DB 連線和 migration 都正常。

### Step 8：確認 Deriver 在運行

```powershell
docker compose logs deriver --tail 20
```

應看到「polling」或「processing」字樣。

---

## 使用其他 LLM Provider（OpenRouter / Ollama）

### 改用 OpenRouter（付費，支援多種模型）

把 `sk-or-v1-你的Key` 換成你的 OpenRouter Key，複製整個區塊貼上：

```powershell
@"
LLM_OPENAI_API_KEY=sk-or-v1-你的Key

DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=google/gemini-2.5-flash
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=https://openrouter.ai/api/v1
"@ | Add-Content -Path ".env"
```

改完後重啟：

```powershell
docker compose restart
```

### 改用 Ollama（本機模型，免費）

先確認 Ollama 已安裝並有在跑：

```powershell
ollama list
```

把設定加入 .env（`host.docker.internal` 讓 Docker 容器連到本機的 Ollama）：

```powershell
@"
DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=llama3.2
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://host.docker.internal:11434/v1
DERIVER_MODEL_CONFIG__OVERRIDES__API_KEY=ollama
"@ | Add-Content -Path ".env"
```

重啟：

```powershell
docker compose restart
```

```
# .env — 使用本機 Ollama
DERIVER_MODEL_CONFIG__TRANSPORT=openai
DERIVER_MODEL_CONFIG__MODEL=llama3.2
DERIVER_MODEL_CONFIG__OVERRIDES__BASE_URL=http://host.docker.internal:11434/v1
```

⚠️ Docker 內的 `localhost` 不是 host。用 `host.docker.internal` 連到 Windows host 上的 Ollama。

---

## 更改設定後重啟

```powershell
docker compose down
docker compose up -d
```

若有改程式碼，需要重新 build：
```powershell
docker compose up -d --build
```

---

## 常見錯誤

| 錯誤 | 原因 | 解法 |
|------|------|------|
| Build 失敗（syntax error） | BuildKit 未開啟 | `$env:DOCKER_BUILDKIT=1; docker compose build` |
| `connection refused :8000` | Container 未啟動 | `docker compose ps`，查看哪個掛掉 |
| `An unexpected error occurred` | 資料庫問題 | `docker compose logs api`，確認 DB 連線 |
| `ValueError: Missing client for Deriver` | LLM API key 未設定 | 確認 `.env` 裡的 key |
| Port 8000 已被占用 | 其他程式用了 8000 | 改 `docker-compose.yml` 的 port 映射 |

---

## 回退方式

若 Docker 環境損壞：
1. `docker compose down -v`（⚠️ -v 會刪除資料 volume，除非有備份不要用）
2. 確認原因後重新 `docker compose up -d --build`

若要保留資料：
1. 先備份：`docker compose exec database pg_dump -U postgres postgres > backup.sql`
2. 再處理問題
