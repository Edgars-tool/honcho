# 00 — 自架伺服器架構

---

## 架構總覽

```
外部請求
    │
    ▼
[Reverse Proxy / Cloudflare Tunnel]（選填，對外公開才需要）
    │
    ▼ HTTPS → HTTP
[Honcho API server: 127.0.0.1:8000]
    │
    ├─── Enqueue ──→ [PostgreSQL Queue Table]
    │                        │
    │                        ▼
    │               [Deriver Worker（背景）]
    │                        │
    ▼                        ▼
[PostgreSQL + pgvector: 127.0.0.1:5432]
    │
[Redis Cache: 127.0.0.1:6379]（選填）
```

---

## 四個 Service

| Service | Container 名 | Port | 說明 |
|---------|-------------|------|------|
| API server | `honcho-api-1` | `127.0.0.1:8000` | FastAPI，HTTP 入口 |
| Deriver worker | `honcho-deriver-1` | 無 | 背景記憶處理 |
| PostgreSQL | `honcho-database-1` | `127.0.0.1:5432` | 主資料庫 |
| Redis | `honcho-redis-1` | `127.0.0.1:6379` | Cache（選填） |

**重要**：所有 port 預設綁定 `127.0.0.1`（localhost only），不對外暴露。

---

## 資料儲存

| 資料 | 存在哪裡 | 格式 |
|------|----------|------|
| Workspaces / Peers / Sessions / Messages | PostgreSQL | 關聯式 |
| Conclusions（向量） | PostgreSQL（pgvector HNSW index） | vector |
| Queue（待處理任務） | PostgreSQL（QueueItem 表） | 關聯式 |
| Session 摘要 | PostgreSQL | 文字 |
| Cache | Redis（in-memory fallback） | key-value |

---

## LLM 依賴

Honcho 本身不含 LLM，需要外部 provider：

| 功能 | 預設 Provider | 可替換為 |
|------|--------------|----------|
| Deriver | OpenAI gpt-4.1-mini | 任何 OpenAI-compatible |
| Dialectic minimal/low | Gemini flash | 任何 OpenAI-compatible |
| Dialectic medium/high/max | Anthropic Claude | 任何 OpenAI-compatible |
| Embeddings | OpenAI text-embedding-3-small | 任何 OpenAI-compatible |
| Dreamer | Anthropic Claude | 任何 OpenAI-compatible |

可全部改為同一個 provider（如 OpenRouter、Ollama）。

---

## 網路設計

```
正確（只本機存取）：
  API: 127.0.0.1:8000 ← 只有本機能連
  DB:  127.0.0.1:5432 ← 只有本機能連
  Redis: 127.0.0.1:6379 ← 只有本機能連

錯誤（不應這樣）：
  API: 0.0.0.0:8000 ← 對所有網路介面開放，危險
```

---

## 什麼時候考慮對外公開

- 你的 AI client 在另一台機器，需要連回 Honcho
- 需要從雲端應用連到本地 Honcho

**安全前提**：
1. 開啟 Auth（`AUTH_USE_AUTH=true`）
2. 設定 JWT secret
3. 使用 HTTPS（reverse proxy 或 Cloudflare Tunnel）
4. 備份完整

---

## 什麼時候只綁 localhost

- 本機開發測試
- AI client 在同一台機器上（Claude Code、OpenClaw 等）
- 不需要遠端存取

→ 這是預設設定，**不需要改任何東西**

---

## 什麼時候考慮 Reverse Proxy / Cloudflare Tunnel

| 情境 | 建議 |
|------|------|
| 局域網內另一台機器需要連 | iptables / firewall 規則，或 SSH tunnel |
| 從外網需要連 | Cloudflare Tunnel（最簡單，不用開 port）或 Nginx + Let's Encrypt |
| VPN 環境 | 走 VPN，不用對外 |

**Cloudflare Tunnel 最簡單**（不需要開 firewall port）：
```powershell
# 安裝 cloudflared 後
cloudflared tunnel create honcho
cloudflared tunnel route dns honcho honcho.yourdomain.com
cloudflared tunnel run honcho
```
詳見 https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/

---

## 關於 Fly.io 部署

官方 repo 包含 `fly.toml` 設定檔，可部署到 Fly.io。
⚠️ 注意：`fly.toml` **不包含** PostgreSQL，需要另外準備（Supabase、Neon、Railway 等）。

```powershell
flyctl launch --no-deploy
# 將 .env 內容載入為 secrets
# cat .env | flyctl secrets import  (Linux 指令，Windows 需調整)
flyctl deploy
```
