# 00 — 驗證 Checklist

> 逐層確認 Honcho 是否正常運行

---

## 驗證順序（重要）

問題定位必須從底層往上：
```
Layer 1: Docker / 進程 是否啟動
Layer 2: Database 是否可連
Layer 3: API 是否正常
Layer 4: SDK 基本功能
Layer 5: 記憶寫入 → 查回（端到端）
Layer 6: 整合工具（MCP / Plugin）
```

---

## Layer 1：進程/Container 啟動

### Docker 模式

```powershell
docker compose ps
```

**預期**：所有 service 狀態為 `running`

| Service | Port | 作用 |
|---------|------|------|
| api | 8000 | HTTP API |
| deriver | - | 記憶背景處理 |
| database | 5432 | PostgreSQL + pgvector |
| redis | 6379 | Cache（選填） |

**失敗**：某個 container `Exit` → `docker compose logs <service>` 看原因

### 手動模式

```powershell
# 確認兩個進程都在跑
Get-Process | Where-Object { $_.Name -like "*python*" -or $_.Name -like "*fastapi*" }
```

---

## Layer 2：Database 健康

```powershell
# 建立 workspace（同時測試 DB 連線 + migration）
$response = Invoke-RestMethod `
    -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name": "verify-test"}'

$response | ConvertTo-Json
```

**預期**：取回含 `id` 欄位的 workspace 物件

**失敗**：
- `"An unexpected error occurred"` → DB 問題
- 看 `docker compose logs api --tail 30` 找真正錯誤
- `sqlalchemy.exc.ProgrammingError: relation does not exist` → migration 沒跑

---

## Layer 3：API 健康

```powershell
# 基本 health check（只確認 process，不確認 DB）
Invoke-RestMethod -Uri "http://localhost:8000/health"
# 預期：{"status":"ok"}

# API 文件是否可開
Start-Process "http://localhost:8000/docs"
```

---

## Layer 4：SDK 基本功能

```python
# verify_sdk.py
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="verify-sdk")

# 建立 peer
user = honcho.peer("test-user")
assistant = honcho.peer("test-assistant")
print(f"✅ Peer 建立成功: user={user.id}, assistant={assistant.id}")

# 建立 session
session = honcho.session("verify-session-001")
session.add_peers([user, assistant])
print(f"✅ Session 建立成功: {session.id}")

# 寫入 messages
messages = [
    user.message("我喜歡貓"),
    assistant.message("我記住了，你喜歡貓"),
]
session.add_messages(messages)
print(f"✅ Messages 寫入成功")
```

```powershell
python verify_sdk.py
```

---

## Layer 5：端到端記憶測試

```python
# verify_memory.py
import time
from honcho import Honcho

honcho = Honcho(base_url="http://localhost:8000", workspace_id="verify-e2e")

user = honcho.peer("e2e-user")
assistant = honcho.peer("e2e-assistant")

session = honcho.session("e2e-session-001")
session.add_peers([user, assistant])

# 寫入幾則有內容的訊息
session.add_messages([
    user.message("我在學 Python，最近在研究 FastAPI，喜歡型別提示"),
    assistant.message("了解，你正在用 FastAPI 開發，並且重視程式碼品質"),
    user.message("對，我討厭沒有 docstring 的程式碼"),
])
print("Messages 寫入完成，等待 Deriver 處理...")

# 等待 Deriver 處理（測試用，實際應用用 webhook 或 queue status）
time.sleep(15)

# 查詢 Dialectic
print("查詢 Dialectic...")
response = user.chat("這個使用者的技術偏好是什麼？")
print(f"\n回答：\n{response}")

# 驗證回答有意義
if "python" in response.lower() or "fastapi" in response.lower() or "型別" in response.lower():
    print("\n✅ 端到端記憶測試通過")
else:
    print("\n⚠️  回答不包含預期內容，可能 Deriver 尚未處理完，再等幾秒重試")
```

```powershell
python verify_memory.py
```

**預期**：Dialectic 回答提到 Python / FastAPI / 型別提示相關內容

---

## Layer 6：Deriver 確認

```powershell
# 確認 Deriver 有在 polling
docker compose logs deriver --tail 30
```

看到「polling」「processing」「Finished」字樣 → Deriver 正常

---

## 整合驗證（MCP）

設定完 MCP 後，在 client 裡說：
> "What do you know about me?"

首次可能沒有，幾次對話後再問，應看到越來越豐富的個人化回答。

---

## 故障定位決策樹

```
API 連不到
  └─ Container 沒起來 → docker compose ps → docker compose logs <service>

API 連得到但 /v3/workspaces 失敗
  └─ DB 問題 → docker compose logs api → 看 sqlalchemy 錯誤
  └─ Migration 沒跑 → docker compose exec api uv run alembic upgrade head

SDK 寫入成功但 Dialectic 沒有回應內容
  └─ Deriver 沒啟動 → docker compose logs deriver
  └─ LLM API key 錯誤 → 看 deriver logs 的 API error
  └─ 等待時間不夠 → 再等久一點

Dialectic 有回應但不相關
  └─ 訊息不夠多 → 多寫幾則有內容的訊息
  └─ REPRESENTATION_BATCH_MAX_TOKENS 太高 → 降低或多寫訊息
```
