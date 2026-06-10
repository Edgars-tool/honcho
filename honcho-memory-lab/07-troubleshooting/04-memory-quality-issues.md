# 04 — 記憶品質問題

---

## 症狀：Dialectic 回應沒有個人化

### 診斷步驟

```
1. 確認訊息有寫入
2. 確認 Deriver 有處理
3. 確認 Conclusions 有建立
4. 測試 Dialectic 查詢
```

**Step 1：確認訊息寫入**

```python
from honcho import Honcho
honcho = Honcho(base_url="http://localhost:8000", api_key="placeholder")

# 列出 session 的訊息
messages = honcho.messages.list(
    workspace_name="my-workspace",
    peer_name="alice",
    session_name="session-1"
)
print(list(messages))
```

**Step 2：確認 Deriver 有處理**

```powershell
# 查看 Deriver log
docker compose logs deriver --tail=50

# 關鍵字：
# "Processing representation task" → 正在處理
# "Completed representation" → 完成
# "ERROR" → 有問題
```

**Step 3：查看 Conclusions**

```python
conclusions = honcho.conclusions.list(
    workspace_name="my-workspace",
    observer_name="alice",
    observed_name="alice"
)
for c in conclusions:
    print(c.content)
```

**Step 4：查詢 Dialectic**

```python
response = honcho.peers.chat(
    workspace_name="my-workspace",
    peer_name="alice",
    queries=["What are Alice's preferences?"]
)
print(response.content)
```

---

## 症狀：記憶內容不準確或有錯誤

### 找出問題 conclusion

```python
# 語義搜尋特定主題
results = honcho.conclusions.query(
    workspace_name="my-workspace",
    observer_name="alice",
    observed_name="alice",
    query="Python programming"
)
for r in results:
    print(r.id, r.content)
```

### 刪除錯誤的 conclusion

```python
honcho.conclusions.delete(
    workspace_name="my-workspace",
    observer_name="alice",
    observed_name="alice",
    conclusion_id="conclusion-id-here"
)
```

---

## 症狀：Deriver 沒有在跑

**確認 queue 狀態**：

```powershell
docker compose exec database psql -U honcho -d honcho -c \
  "SELECT status, COUNT(*) FROM queue_items GROUP BY status;"
```

如果 `status = 'pending'` 持續增加但 `processing` 沒有增加：

```powershell
# 重啟 deriver
docker compose restart deriver

# 查看 deriver 是否有錯
docker compose logs deriver --tail=20
```

---

## 症狀：記憶太慢出現

Deriver 是非同步的，訊息寫入後需要時間處理。

| 情況 | 預期等待時間 |
|------|-------------|
| 輕量負載（dev） | 3–15 秒 |
| 中量訊息 | 15–60 秒 |
| LLM 速度慢（Ollama） | 1–5 分鐘 |

**加快方法**：
- 增加 Deriver workers（`.env` 中 `DERIVER_WORKERS=2`）
- 使用更快的 LLM provider

---

## 症狀：記憶品質差（推論不準）

**可能原因**：
- 訊息 content 太短或無意義
- LLM prompt 不符合你的使用情境

**預防建議**：
- 每次 session 的訊息要有足夠上下文
- 避免把 debug 訊息、log 輸出寫入 session
- 測試用資料放在獨立 workspace（`workspace_name="test"`）
