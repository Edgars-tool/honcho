# honcho-memory-lab

> Honcho 記憶系統完整實驗室：學習、安裝、驗證、維運、自架、整合

---

## 🚀 沒有科技背景？從這裡開始

**→ [`00-beginner-start.md`](./00-beginner-start.md)**

不需要懂程式。照著步驟把指令複製貼上到終端機，15 分鐘內跑完第一個 Honcho 記憶測試。

> **如何複製貼上到 PowerShell**：在黑色視窗上按「右鍵」即可貼上（不是 Ctrl+V）。

---

## 這個專案是什麼

這是一個圍繞 [Honcho](https://honcho.dev)（AI 記憶基礎設施）建立的完整知識庫與操作手冊，涵蓋從概念理解、安裝部署、SDK 整合、自架伺服器到維運除錯的所有環節。

Honcho 是 AI Agent 的記憶層，讓 LLM-powered 應用能跨 session 記住使用者、建立心理模型、個人化回應。

---

## 適合誰

- **完全沒有程式背景** → 從 `00-beginner-start.md` 開始
- 正在評估 Honcho 是否適合你的 AI 工作流的人
- 想要自架 Honcho（不依賴雲端）的開發者
- 把 Honcho 整合到 OpenClaw / Claude Code / MCP 的使用者
- 已上線後需要維運 Honcho 的工程師

---

## 現在不要做什麼

- ❌ 不要把 API key 或 secret 寫進任何檔案或 repo
- ❌ 不要把 `.env` commit 進 git
- ❌ 不要掃描 Edgars_secret 目錄
- ❌ 不要在沒有設定 auth 的情況下對外公開 Honcho
- ❌ 不要跳過 backup，直接升級

---

## 學習路線

```
01-learning/
├─ 00-Honcho-系統地圖.md        ← 先看這個，建立全局觀
├─ 01-核心概念.md               ← Workspace / Peer / Session / Message
├─ 02-Agent-Memory-記憶流.md    ← Deriver / Dialectic / Dreamer
├─ 03-API-SDK-串接.md           ← Python / TypeScript SDK 使用
└─ 04-OpenClaw-ClaudeCode-MCP-整合.md ← 整合評估
```

---

## 安裝路線

```
02-install/
├─ 00-install-options.md        ← 三條路線比較，先看這個決定走哪條
├─ 01-managed-cloud-setup.md    ← A. Managed Cloud（最快）
├─ 02-self-host-docker-setup.md ← B. Local/Self-host（Docker Compose）
├─ 03-windows-local-setup.md    ← C. Windows 本機（特殊情境）
└─ 04-env-template.md           ← 環境變數清單
```

---

## 驗證路線

```
03-verification/
├─ 00-verification-checklist.md ← 逐步驗證清單
├─ 01-healthcheck.md            ← server / DB / Redis 三層健康檢查
├─ 02-sdk-smoke-test.md         ← SDK 基本功能測試
└─ 03-context-retrieval-test.md ← 記憶寫入 → 查回 端到端測試
```

---

## 維運路線

```
04-operations/
├─ 00-maintenance-runbook.md    ← 日常/週/月 runbook
├─ 01-backup-restore.md         ← 備份與還原
├─ 02-logs-debugging.md         ← log 查看與除錯
├─ 03-upgrade-policy.md         ← 升級流程
└─ 04-memory-hygiene.md         ← 記憶品質維護
```

---

## 自架伺服器路線

```
05-self-host-server/
├─ 00-server-architecture.md   ← 架構總覽
├─ 01-docker-compose-notes.md  ← docker-compose 細節
├─ 02-network-and-ports.md     ← port / network 設定
├─ 03-security-boundaries.md   ← 安全邊界
└─ 04-production-readiness.md  ← 上線前檢查
```

---

## 整合評估路線

```
06-integration/
├─ 00-integration-map.md        ← 整合全景
├─ 01-openclaw-integration.md   ← OpenClaw 整合
├─ 02-claude-code-integration.md← Claude Code Plugin 整合
├─ 03-mcp-integration.md        ← MCP server 整合
└─ 04-agent-memory-policy.md    ← 記憶寫入/讀取策略
```

---

## 除錯時先看哪裡

1. `docker compose logs api --tail 50` — API 層錯誤
2. `docker compose logs deriver --tail 50` — 記憶處理錯誤
3. `curl http://localhost:8000/v3/workspaces` — 資料庫是否正常
4. `07-troubleshooting/00-common-issues.md` — 常見問題索引
5. `03-verification/00-verification-checklist.md` — 逐層定位

---

## 安全提醒（一次性）

- `.env` 加入 `.gitignore`
- API key 用 placeholder 填範例，真實 key 只存本機
- self-host 對外前確認：auth on、reverse proxy、backup ready
- 測試只用假資料
