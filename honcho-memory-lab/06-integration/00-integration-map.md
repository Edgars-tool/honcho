# 00 — 整合地圖

---

## 整合全景

```
你的工作流
│
├─ OpenClaw ─────────────────→ Honcho API
│    (plugin: openclaw-honcho)  ↑
│                               │
├─ Claude Code ─────────────→ Honcho API
│    (plugin: claude-honcho)    ↑
│                               │
├─ Claude Desktop ──────────→ Honcho MCP server → Honcho API
│    (MCP via mcp-remote)       ↑
│                               │
├─ Cursor ──────────────────→ Honcho MCP server → Honcho API
│    (原生 HTTP MCP)             ↑
│                               │
├─ 自建 Agent ──────────────→ Honcho Python/TS SDK → Honcho API
│
└─ 任何 MCP client ─────────→ https://mcp.honcho.dev → Honcho API
```

---

## 整合方式分類

| 方式 | 適合 | 特性 |
|------|------|------|
| **Claude Code Plugin** | Claude Code 使用者 | 最深度整合，自動記憶注入，git 感知 |
| **OpenClaw Plugin** | OpenClaw 使用者 | 全通道記憶（WhatsApp/Telegram/Discord） |
| **MCP Server（雲端）** | 任何 MCP client | 最通用，設定最簡單，需要 Honcho API key |
| **MCP Server（自架）** | 資料主權需求 | 完全本機，需自架 Honcho |
| **Python/TS SDK** | 自建 Agent | 最彈性，完整 API 存取 |

---

## 選擇指南

```
你用 Claude Code？
  → 裝 claude-honcho plugin（最好）
  → 或設定 MCP server（次之）

你用 OpenClaw？
  → 裝 openclaw-honcho plugin

你用 Cursor / Windsurf / VS Code Copilot？
  → 設定 Honcho MCP server

你在自建 AI Agent？
  → 用 Python / TypeScript SDK 直接呼叫 API

你需要資料在本地？
  → 先自架 Honcho（Docker Compose）
  → 然後把上面任何整合的 endpoint 改為 localhost:8000
```

---

## 詳細文件

- `01-openclaw-integration.md`
- `02-claude-code-integration.md`
- `03-mcp-integration.md`
- `04-agent-memory-policy.md`
