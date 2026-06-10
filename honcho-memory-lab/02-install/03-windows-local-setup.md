# 03 — Windows 本機安裝（不用 Docker）

> 路線 C：手動安裝各元件，適合開發學習

---

## 適用情境

- Windows 本機開發環境
- 不使用 Docker
- 想深入了解各元件

## 前置需求

- Python 3.10+（建議 3.12）
- uv（Python 套件管理器）
- Git for Windows
- PostgreSQL 15+（含 pgvector extension）
- Redis（選填，可不裝）
- LLM API key

---

## Step 1：安裝 uv

```powershell
# 在 PowerShell 執行
irm https://astral.sh/uv/install.ps1 | iex
```

驗證：
```powershell
uv --version
```

---

## Step 2：Clone & 安裝 Python 依賴

```powershell
git clone https://github.com/plastic-labs/honcho.git
cd honcho
uv sync
```

---

## Step 3：安裝 PostgreSQL

從 https://www.postgresql.org/download/windows/ 下載安裝程式。

安裝時記住：
- port：5432（預設）
- superuser password：自訂，記住它

---

## Step 4：安裝 pgvector extension

pgvector 在 Windows 上需要額外安裝。有兩種方式：

**方式 A（推薦）：用 Docker 跑 PostgreSQL**
```powershell
docker run --name honcho-db `
    -e POSTGRES_USER=postgres `
    -e POSTGRES_PASSWORD=postgres `
    -p 5432:5432 `
    -d pgvector/pgvector:pg15
```
這樣不需要手動裝 pgvector。

**方式 B：在本機 PostgreSQL 安裝 pgvector**

缺資料：pgvector 在 Windows 上的安裝步驟依版本而異，建議參考官方 repo：
https://github.com/pgvector/pgvector#windows

啟用 extension（連線到 PostgreSQL 後）：
```sql
CREATE EXTENSION IF NOT EXISTS vector;
```

---

## Step 5：設定環境變數

```powershell
Copy-Item .env.template .env
```

編輯 `.env`：

```
# LLM
LLM_OPENAI_API_KEY=sk-placeholder

# 資料庫（注意：必須用 postgresql+psycopg，不是 postgresql）
DB_CONNECTION_URI=postgresql+psycopg://postgres:postgres@localhost:5432/postgres

# 關閉認證（開發用）
AUTH_USE_AUTH=false

# Log
LOG_LEVEL=DEBUG
```

---

## Step 6：跑 Database Migration

```powershell
uv run alembic upgrade head
```

---

## Step 7：啟動 API Server

```powershell
# 終端機 1
uv run fastapi dev src/main.py
```

等看到 `Application startup complete`。

---

## Step 8：啟動 Deriver Worker

```powershell
# 終端機 2（新開一個 PowerShell）
cd honcho  # 確認在 honcho 目錄
uv run python -m src.deriver
```

---

## 驗證

```powershell
# 在第三個終端機
Invoke-RestMethod -Uri "http://localhost:8000/health"
# 預期：{"status":"ok"}

Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST -ContentType "application/json" `
    -Body '{"name": "test"}'
# 預期：workspace 物件
```

---

## 注意事項

- **必須同時跑兩個進程**：API server 和 Deriver worker
- API server 掛掉 → HTTP 呼叫失敗
- Deriver worker 沒跑 → message 存入但不會形成記憶
- Redis 不安裝沒關係，Honcho 會 fallback 到 in-memory cache

---

## 常見錯誤

| 錯誤 | 解法 |
|------|------|
| `ModuleNotFoundError` | 確認用 `uv run`，不是直接 `python` |
| `psycopg.OperationalError` | 確認 PostgreSQL 在跑，connection URI 正確 |
| `relation does not exist` | 尚未跑 `uv run alembic upgrade head` |
| Deriver 沒有在處理 | 確認 LLM API key 設定，查看 Deriver 終端輸出 |
