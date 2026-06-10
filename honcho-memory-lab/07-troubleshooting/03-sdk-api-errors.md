# 03 — SDK / API 錯誤

---

## Python SDK

### ImportError

```
ModuleNotFoundError: No module named 'honcho'
```

**修復**：

```powershell
pip install honcho-ai --break-system-packages
# 或
uv pip install honcho-ai
```

---

### 連線錯誤（Self-hosted）

```
httpx.ConnectError: [Errno 111] Connection refused
```

**原因**：`base_url` 設定錯誤，或 server 未啟動。

**修復**：

```python
from honcho import Honcho

# 確認 base_url 格式（結尾不要有斜線）
honcho = Honcho(
    api_key="placeholder",
    base_url="http://localhost:8000",  # ← 不是 /v3
)
```

---

### 401 Unauthorized

```json
{"detail": "Invalid authentication credentials"}
```

**原因**：API key 錯誤，或 server 開啟了 auth 但 key 未設定。

**修復**：

```python
# 開發時關閉 auth（.env）
AUTH_USE_AUTH=false

# 或提供正確 key
honcho = Honcho(api_key="hch-your-actual-key")
```

---

### 404 Not Found

**原因**：workspace 或 peer 不存在。

**修復**：

```python
# 先確認 workspace 存在
workspace = honcho.workspaces.get_or_create(name="my-workspace")

# 再操作 peer
peer = honcho.peers.get_or_create(workspace_name="my-workspace", name="alice")
```

---

### ValidationError（欄位格式）

```
pydantic.ValidationError: ...
```

**常見**：content 欄位不能為空、messages list 超過 100 筆。

```python
# 批次上限：100 筆
session.add_messages(messages[:100])  # 超過 100 需分批
```

---

## HTTP API（PowerShell）

### 基本測試

```powershell
# 測試 API 是否正常
Invoke-RestMethod -Uri http://localhost:8000/healthcheck

# 測試 workspace 建立
$headers = @{ "Authorization" = "Bearer placeholder" }
$body = @{ name = "test-workspace" } | ConvertTo-Json
Invoke-RestMethod -Uri http://localhost:8000/v3/workspaces -Method POST -Headers $headers -Body $body -ContentType "application/json"
```

### 常見 HTTP 錯誤碼

| 碼 | 意義 | 通常原因 |
|----|------|----------|
| 401 | 未授權 | API key 錯誤 |
| 403 | 禁止 | key 無權限 |
| 404 | 找不到 | resource 不存在 |
| 422 | 格式錯誤 | request body 格式問題 |
| 500 | 伺服器錯誤 | DB/service 問題，查 server logs |

---

## TypeScript SDK

### 安裝問題

```powershell
npm install honcho-ai
# 或
bun add honcho-ai
```

### 連線設定

```typescript
import Honcho from "honcho-ai";

const honcho = new Honcho({
  apiKey: "placeholder",
  baseURL: "http://localhost:8000",  // self-hosted
});
```

---

## 收集 debug 資訊

問題回報時請提供：

```powershell
# 1. 版本
python -c "import honcho; print(honcho.__version__)"

# 2. Server log（最近 50 行）
docker compose logs api --tail=50

# 3. Request/Response（Python）
import logging
logging.basicConfig(level=logging.DEBUG)
```
