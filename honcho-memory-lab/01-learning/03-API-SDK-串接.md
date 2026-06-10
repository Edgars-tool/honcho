# 03 — API & SDK 串接

> Python SDK / TypeScript SDK / 直接 HTTP API 使用方式

---

## 安裝 SDK

```powershell
# Python
pip install honcho-ai
# 或
uv add honcho-ai

# TypeScript
npm install @honcho-ai/sdk
# 或
pnpm add @honcho-ai/sdk
```

---

## 初始化（Managed Cloud）

```python
# Python
from honcho import Honcho

honcho = Honcho(
    workspace_id="my-app",
    api_key="hch-your-key-here"  # placeholder
)
```

```typescript
// TypeScript
import { Honcho } from '@honcho-ai/sdk';

const honcho = new Honcho({
  workspaceId: "my-app",
  apiKey: "hch-your-key-here"  // placeholder
});
```

---

## 初始化（Self-hosted）

```python
# Python
from honcho import Honcho

honcho = Honcho(
    base_url="http://localhost:8000",
    workspace_id="my-app"
    # self-host 預設 AUTH_USE_AUTH=false，不需要 api_key
)
```

```typescript
// TypeScript
const honcho = new Honcho({
  baseUrl: "http://localhost:8000",
  workspaceId: "my-app"
});
```

---

## 完整流程範例（Python）

```python
import json
from honcho import Honcho

# 初始化
honcho = Honcho(workspace_id="test", api_key="hch-placeholder")

# 建立 peers
user = honcho.peer("user-alice")
assistant = honcho.peer("assistant-claude")

# 建立 session 並加入 peers
session = honcho.session("session-001")
session.add_peers([user, assistant])

# 寫入 messages
messages = [
    user.message("我在做一個個人財務 app，想讓它記住使用者的偏好"),
    assistant.message("這很有意思！你希望它記住哪些偏好？"),
    user.message("比如說不喜歡訂閱制、很在意衝動消費"),
]
session.add_messages(messages)

# 等待 Deriver 處理（開發用）
import time
time.sleep(5)

# 查詢 Dialectic
response = user.chat("這個使用者最在意什麼？")
print(response)
```

---

## 完整流程範例（TypeScript）

```typescript
import { Honcho } from '@honcho-ai/sdk';

const honcho = new Honcho({
  workspaceId: "test",
  apiKey: "hch-placeholder"
});

const user = await honcho.peer("user-alice");
const assistant = await honcho.peer("assistant-claude");

const session = await honcho.session("session-001");
await session.addPeers([user, assistant]);

await session.addMessages([
  user.message("我在做一個個人財務 app"),
  assistant.message("聽起來很有趣！"),
]);

// 查詢
const response = await user.chat("這個使用者最在意什麼？");
console.log(response);
```

---

## 直接 HTTP API（PowerShell / curl）

```powershell
# 建立 workspace
$body = '{"name": "test"}' | ConvertFrom-Json | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST `
    -ContentType "application/json" `
    -Body '{"name": "test"}'

# 查詢所有 workspaces
Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" -Method POST `
    -ContentType "application/json" -Body '{}'
```

---

## 常用 API 端點

| 操作 | 方法 | 路徑 |
|------|------|------|
| 建立/取得 workspace | POST | `/v3/workspaces/{id}` |
| 建立/取得 peer | POST | `/v3/workspaces/{wid}/peers/{id}` |
| 建立/取得 session | POST | `/v3/workspaces/{wid}/sessions/{id}` |
| 寫入 messages | POST | `/v3/workspaces/{wid}/sessions/{sid}/messages` |
| Dialectic chat | POST | `/v3/workspaces/{wid}/peers/{pid}/chat` |
| 查詢 conclusions | POST | `/v3/workspaces/{wid}/peers/{pid}/conclusions/query` |
| Health check | GET | `/health` |
| Queue status | GET | `/v3/workspaces/{wid}/queue-status` |

完整 API Reference：https://honcho.dev/docs/v3/api-reference/introduction

---

## Queue Status 查詢

```python
# 確認 Deriver 是否處理完畢
import time
from honcho import Honcho

honcho = Honcho(workspace_id="test", api_key="hch-placeholder")

while True:
    status = honcho.workspaces.get_queue_status(workspace_id="test")
    if status.pending == 0:
        print("處理完成")
        break
    print(f"Pending: {status.pending}")
    time.sleep(2)
```

---

## 重要注意事項

1. **Deriver 非同步**：message 寫入後不會立即可查，需等待 Deriver 處理
2. **connection URI 格式**：self-host 時資料庫 URI 必須用 `postgresql+psycopg://`，不是 `postgresql://`
3. **Auth 預設關閉**：self-host 預設 `AUTH_USE_AUTH=false`，開發方便；production 務必開啟
4. **批次限制**：每次 `add_messages` 最多 100 則
