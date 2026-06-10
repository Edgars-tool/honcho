# 00 — Honcho 系統地圖

> 快速建立 Honcho 全局觀，再深入各子系統

---

## 一句話定義

Honcho 是讓 AI 「記住你是誰」的推論引擎。它不只存對話，它主動分析、推論、整合，建立跨 session 的使用者心理模型。

---

## 四大核心組成

```
┌─────────────────────────────────────────────────┐
│                  Honcho 系統                     │
│                                                  │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │  API     │  │ Deriver  │  │   Dreamer    │   │
│  │ (HTTP)   │  │(記憶形成) │  │  (記憶整合)  │   │
│  └──────────┘  └──────────┘  └──────────────┘   │
│       │              │              │             │
│  ┌──────────────────────────────────────────┐    │
│  │           Dialectic (記憶查詢)            │    │
│  └──────────────────────────────────────────┘    │
│                      │                           │
│         ┌────────────┴────────────┐              │
│         ▼                         ▼              │
│   PostgreSQL + pgvector       Redis Cache        │
└─────────────────────────────────────────────────┘
```

---

## API 層

- FastAPI 應用，監聽 port 8000
- 處理所有 HTTP 請求（建立 workspace、peer、session、message）
- 接收 message 後，enqueue 給 Deriver 處理
- Dialectic agent 在 API 進程內運行（同步）

---

## Deriver（記憶形成）

- 背景 worker，獨立進程
- 消費 queue 裡的 message，呼叫 LLM 萃取「結論（conclusions）」
- 結論分兩種：
  - **Explicit conclusions**：對話中直接提到的事實
  - **Deductive conclusions**：從事實推論出的洞察
- 預設 1 個 worker，高負載可增加 `DERIVER_WORKERS`

---

## Dialectic（記憶查詢）

- 回答「這個 peer 是什麼樣的人」的推論 agent
- 在 API 進程內同步運行（每次 `/peers/{id}/chat` 請求）
- 有五個推論層級：`minimal` → `low` → `medium` → `high` → `max`
- `minimal` 層：只用 `search_memory` + `search_messages`（最快、最省）
- `max` 層：使用全套工具、最強推論能力

---

## Dreamer（記憶整合）

- 週期性執行的整合 agent（排程 + 可手動觸發）
- 兩個 specialist：
  - **DeductionSpecialist**：從 explicit 結論產生 deductive 結論
  - **InductionSpecialist**：從所有結論產生 inductive 結論
- 建立 reasoning tree（推論鏈），支援 `get_reasoning_chain` 查詢
- 讓記憶越來越深、越來越整合

---

## 核心資料模型

| 概念 | 說明 |
|------|------|
| **Workspace** | 最頂層的命名空間（原名 App） |
| **Peer** | 任何參與者：使用者或 AI agent（原名 User） |
| **Session** | 一次對話上下文，可包含多個 peer |
| **Message** | 對話中的單一訊息，或任意資料輸入 |
| **Conclusions** | 從 message 萃取的結論（API 層名稱）；程式碼內稱 observations |
| **Collection** | 向量儲存，以 (observer, observed) peer pair 為 key |

---

## 資料流總覽

```
1. 你的應用呼叫 API: POST /sessions/{id}/messages
2. API 存入 PostgreSQL，enqueue 給 Deriver
3. Deriver 讀取 message，呼叫 LLM 萃取結論
4. 結論存入 Collection（vector store）
5. 你的應用呼叫: POST /peers/{id}/chat?query=...
6. Dialectic 查詢 Collection，推論回答
7. Dreamer 定期整合所有結論，產生更深的推論
```

---

## 兩個進程

Honcho 運行時有兩個獨立進程，共享同一個 PostgreSQL 和 Redis：

| 進程 | 指令 | 用途 |
|------|------|------|
| API server | `uv run fastapi dev src/main.py` | 處理 HTTP 請求，Dialectic 在此 |
| Deriver worker | `uv run python -m src.deriver` | 背景記憶形成，Dreamer 在此 |

Docker Compose 會自動啟動這兩個進程（`api` 和 `deriver` 兩個 service）。

---

## 下一步

- 詳細概念 → `01-核心概念.md`
- 記憶流細節 → `02-Agent-Memory-記憶流.md`
- SDK 串接 → `03-API-SDK-串接.md`
