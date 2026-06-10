# 00 — 安裝路線比較

> 三條路線：Managed Cloud / Local Docker / Windows 本機

---

## 三條路線快速比較

| | A. Managed Cloud | B. Self-host Docker | C. Windows 本機 |
|---|---|---|---|
| **速度** | 5 分鐘 | 15-30 分鐘 | 30-60 分鐘 |
| **複雜度** | 低 | 中 | 高 |
| **資料控制** | 雲端托管 | 完全自控 | 完全自控 |
| **需要 Docker** | ❌ | ✅ | 選填 |
| **費用** | 按用量（新帳戶 $100 免費額度） | 自行承擔主機費 | 本機無費用 |
| **對外公開** | 自動 | 需自行設定 | 需額外設定 |
| **適合情境** | 快速試用、production SaaS | 資料主權、企業內網 | 本機開發測試 |

---

## 路線 A：Managed Cloud（最快）

**適合**：評估期、快速 PoC、不想管基礎設施

1. 到 https://app.honcho.dev 註冊
2. 取得 API key（以 `hch-` 開頭）
3. 安裝 SDK：`pip install honcho-ai`
4. 設定 API key，開始使用

→ 詳細：`01-managed-cloud-setup.md`

---

## 路線 B：Self-host Docker（推薦）

**適合**：資料主權需求、企業內網、production self-host

Docker Compose 會自動啟動四個 service：
- `api`（port 8000）
- `deriver`（背景 worker）
- `database`（PostgreSQL + pgvector，port 5432）
- `redis`（port 6379）

⚠️ **重要**：Honcho 沒有預建的 Docker Hub image。`docker compose up --build` 會從 source 編譯，第一次需要幾分鐘。

→ 詳細：`02-self-host-docker-setup.md`

---

## 路線 C：Windows 本機（特殊情境）

**適合**：Windows 開發環境、不使用 Docker、學習目的

需要手動安裝 PostgreSQL + pgvector、Redis，並分別啟動 API server 和 Deriver worker。

→ 詳細：`03-windows-local-setup.md`

---

## 決策流程

```
想快速試用？
  → A. Managed Cloud

需要資料完全在本地/內網？
  → 有 Docker？ → B. Self-host Docker（推薦）
  → 沒有 Docker / Windows 開發機 → C. Windows 本機

不確定？
  → 先 A，評估後再考慮 B
```

---

## 共用前置需求

無論哪條路線，都需要：

- **LLM API key**（至少一個，預設用 OpenAI）
  - 最簡設定：`LLM_OPENAI_API_KEY=sk-placeholder`
  - 也可用 OpenRouter、Gemini、Anthropic 或 Ollama

- **Python 或 Node.js**（用 SDK 時）

- **Git**（self-host 需要 clone repo）
