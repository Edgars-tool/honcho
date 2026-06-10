# 04 — Agent Memory Policy

> 記憶寫入與讀取策略設計

---

## 寫入策略

### 什麼應該寫入

- 使用者說的話（真實對話內容）
- 使用者的偏好、工作習慣、背景
- 有意義的 assistant 回應

### 什麼不應該寫入

- Debug log、error message
- 系統通知、平台 metadata
- 測試訊息（用獨立 workspace 隔離）
- 不確定是否真實的假設

### 批次 vs 即時

```python
# 建議：每次對話結束後批次寫入
messages = [
    user.message(user_turn),
    assistant.message(assistant_turn),
]
session.add_messages(messages)

# 不建議：每則訊息獨立寫（效能差）
session.add_messages([user.message(user_turn)])
session.add_messages([assistant.message(assistant_turn)])
```

---

## 讀取策略

### 何時讀取記憶

| 情境 | 方式 | 說明 |
|------|------|------|
| 新對話開始 | `peer.chat()` 或 `get_peer_context()` | 取得使用者背景 |
| 需要即時個人化 | `conclusions.query()` 語義搜尋 | 找特定主題的記憶 |
| 長對話摘要 | `session.get_context()` | 取得 session 摘要 |

### 避免過度查詢

Dialectic（`peer.chat()`）每次都呼叫 LLM，有成本。
若只需要事實查詢，用 `conclusions.query()`（純向量搜尋，便宜）。

---

## Session 設計策略

### 一個使用者多個 session

```python
# 每次對話建立新 session（推薦）
import uuid
session_id = f"user-{user_id}-{date.today()}-{uuid.uuid4().hex[:8]}"
session = honcho.session(session_id)

# 或使用固定 session（不推薦，會變很長）
session = honcho.session("user-alice-forever")
```

建議：每次獨立對話建立新 session，讓 Summarizer 有機會建立摘要。

### Multi-peer session

```python
# 適合多人對話場景
session = honcho.session("group-chat-001")
session.add_peers([user_alice, user_bob, assistant])
```

---

## 等待 Deriver 的策略

| 場景 | 建議 |
|------|------|
| 測試/開發 | `time.sleep(10-30)` |
| 生產環境 | Webhook 或 queue status polling |
| 不需要即時記憶 | 不等待，下次對話時記憶已就緒 |

```python
# Queue status polling（生產用）
import time
from honcho import Honcho

def wait_for_processing(honcho, workspace_id, timeout=60):
    start = time.time()
    while time.time() - start < timeout:
        status = honcho.workspaces.get_queue_status(workspace_id=workspace_id)
        if getattr(status, 'pending', 0) == 0:
            return True
        time.sleep(3)
    return False  # timeout
```

---

## Dialectic 推論層級選擇

| 用途 | 層級 | 說明 |
|------|------|------|
| 快速事實查詢 | `minimal` | 只用 search_memory + search_messages |
| 一般個人化 | `low` / `medium` | 平衡速度與深度 |
| 深度分析 | `high` / `max` | 完整推論，速度較慢 |

```python
# 指定層級（若 SDK 支援）
response = user.chat(
    "What are this user's communication preferences?",
    # reasoning_level="minimal"  # 缺資料：SDK 是否支援此參數需確認
)
```

或透過 API：
```
POST /peers/{id}/chat
{
  "queries": ["What are the user's preferences?"],
  "reasoning_level": "minimal"
}
```
