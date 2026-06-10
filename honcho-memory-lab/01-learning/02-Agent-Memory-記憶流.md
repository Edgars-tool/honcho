# 02 — Agent Memory 記憶流

> Deriver / Dialectic / Dreamer 運作細節

---

## 完整記憶流

```
你的 App 寫入 Message
        │
        ▼
   API server 收到
        │
        ▼
   enqueue 給 Deriver
        │
        ▼
┌─────────────────────────────────────────┐
│               Deriver                   │
│  ┌─────────────────────────────────┐    │
│  │ 1. 讀取 message batch           │    │
│  │ 2. 呼叫 LLM（single call）      │    │
│  │ 3. 萃取 explicit conclusions    │    │
│  │ 4. 萃取 deductive conclusions   │    │
│  │ 5. 存入 Collection (pgvector)   │    │
│  └─────────────────────────────────┘    │
└─────────────────────────────────────────┘
        │
        ▼（週期性）
┌─────────────────────────────────────────┐
│               Dreamer                   │
│  DeductionSpecialist → InductionSpec    │
│  整合結論 → 建立 reasoning tree         │
└─────────────────────────────────────────┘
        │
        ▼（你的 App 查詢）
┌─────────────────────────────────────────┐
│              Dialectic                  │
│  工具循環 → 查詢 Collection             │
│  推論回答 → 返回自然語言                 │
└─────────────────────────────────────────┘
```

---

## Deriver 細節

**觸發**：每次 message 寫入後自動 enqueue

**架構**：「Minimal Deriver」— 每個 batch 只呼叫一次 LLM（structured output）
- 不是 agentic tool loop，是單一 LLM call
- 可預測成本，低延遲
- 預設模型：`gpt-4.1-mini`（OpenAI）或依設定覆蓋

**Token 批次**：
- 預設等待 message 累積到足夠 token 才觸發
- 由 `REPRESENTATION_BATCH_MAX_TOKENS` 控制
- 若訊息少、等不到足夠 token，可能看起來沒有在處理

**多 worker**：
```
# .env
DERIVER_WORKERS=4
```

---

## Dialectic 細節

**觸發**：API 呼叫 `POST /peers/{id}/chat`

**五個推論層級**：

| 層級 | 工具集 | 適用情境 |
|------|--------|----------|
| `minimal` | `search_memory` + `search_messages` | 最快、最省 |
| `low` | + 部分額外工具 | 一般查詢 |
| `medium` | 標準工具集 | 平衡 |
| `high` | 完整工具集 | 深度查詢 |
| `max` | 完整工具集 + 最強模型 | 最深推論 |

**工具清單**（`medium` 以上）：
- `search_memory`：向量搜尋 conclusions
- `search_messages`：搜尋原始 messages
- `get_observation_context`：取得結論脈絡
- `grep_messages`：關鍵字搜尋 messages
- `get_messages_by_date_range`：日期範圍搜尋
- `search_messages_temporal`：時間序列搜尋
- `get_reasoning_chain`：取得推論鏈（Dreamer 建立的）

**呼叫範例**：

```python
response = user.chat(
    "What should I know about this user? 3 sentences max",
    # reasoning_level="minimal"  # 可指定層級
)
print(response)
```

---

## Dreamer 細節

**觸發**：
- 週期性排程（DreamScheduler，在 Deriver worker 進程內）
- 手動觸發：`POST /workspaces/{id}/dream`

**兩階段**：

1. **DeductionSpecialist**：
   - 輸入：Explicit conclusions
   - 輸出：Deductive conclusions（邏輯推演）

2. **InductionSpecialist**：
   - 輸入：Explicit + Deductive conclusions
   - 輸出：Inductive conclusions（跨事實歸納）

**Surprisal 優先**：Dreamer 用 surprisal 算法決定先整合哪些結論
（最「令人驚訝」的結論優先整合，效果最好）

**Reasoning Tree**：
- 每個結論都連結到它的前提（premises）和下游結論
- 支援 `get_reasoning_chain` 追蹤推論路徑

---

## Summarizer 細節

**觸發**：每次 Deriver 處理 message 時一起執行

**兩層摘要**：

| 類型 | 每幾則訊息 | 預設 |
|------|-----------|------|
| Short summary | 每 N 則 | 20 則 |
| Long summary | 每 N 則 | 60 則 |

可透過環境變數調整：
```
SUMMARY_MESSAGES_PER_SHORT_SUMMARY=20
SUMMARY_MESSAGES_PER_LONG_SUMMARY=60
```

---

## 等待記憶處理的方法

訊息寫入後，記憶不是立即可查的。可以：

1. **等待固定時間**：簡單 sleep（開發測試用）
2. **查詢 queue status**：
   ```python
   status = client.workspaces.get_queue_status(workspace_id="my-app")
   # 等 pending 降為 0
   ```
3. **Webhook**：設定 webhook 接收處理完成通知

---

## 記憶不更新的常見原因

1. Deriver worker 沒有啟動
2. LLM API key 未設定（Deriver 啟動失敗）
3. `REPRESENTATION_BATCH_MAX_TOKENS` 太高，訊息不夠多
4. Queue 積壓（單 worker 高負載）

→ 詳見 `07-troubleshooting/`
