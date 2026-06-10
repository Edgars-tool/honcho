# 04 — OpenClaw / Claude Code / MCP 整合評估

> 現狀評估：哪些是真的接通，哪些是設計稿

---

## 整合狀態總覽

| 整合對象 | 狀態 | 整合方式 | 需要什麼 |
|----------|------|----------|----------|
| **MCP (通用)** | ✅ Production ready | `https://mcp.honcho.dev` 雲端 MCP server | Honcho API key |
| **Claude Code** | ✅ Production ready | `/plugin marketplace add plastic-labs/claude-honcho` | Bun、Honcho API key |
| **OpenClaw** | ✅ Production ready | `@honcho-ai/openclaw-honcho` plugin | OpenClaw、Honcho API key 或 self-host |
| **Cursor** | ✅ 官方支援 | 原生 HTTP MCP，設定 `~/.cursor/mcp.json` | Honcho API key |
| **Codex** | ✅ 官方支援 | `mcp-remote` bridge | Node.js、Honcho API key |
| **Claude Desktop** | ✅ 官方支援 | `mcp-remote` + `npx` | Node.js、Honcho API key |

---

## MCP 整合（通用）

MCP server URL：`https://mcp.honcho.dev`（雲端托管）

### Claude Code 設定（一行指令）

```bash
claude mcp add honcho \
  --transport http \
  --url "https://mcp.honcho.dev" \
  --header "Authorization: Bearer hch-your-key-here" \
  --header "X-Honcho-User-Name: YourName"
```

### Claude Desktop 設定（Windows 路徑）

編輯 `%APPDATA%\Claude\claude_desktop_config.json`：

```json
{
  "mcpServers": {
    "honcho": {
      "command": "npx",
      "args": [
        "mcp-remote",
        "https://mcp.honcho.dev",
        "--header",
        "Authorization:${AUTH_HEADER}",
        "--header",
        "X-Honcho-User-Name:${USER_NAME}"
      ],
      "env": {
        "AUTH_HEADER": "Bearer hch-placeholder",
        "USER_NAME": "YourName"
      }
    }
  }
}
```

### MCP Headers 說明

| Header | 必填 | 說明 |
|--------|------|------|
| `Authorization` | ✅ | `Bearer hch-your-key` |
| `X-Honcho-User-Name` | ✅ | 你的名字（AI 如何稱呼你） |
| `X-Honcho-Assistant-Name` | 選填 | AI peer 的名字（預設 "Assistant"） |
| `X-Honcho-Workspace-ID` | 選填 | 指定 workspace（預設 "default"） |

### MCP 可用工具（重要的幾個）

- `chat`：查詢 Honcho 對 user 的了解（Dialectic）
- `create_session` + `add_messages_to_session`：寫入對話
- `query_conclusions`：語義搜尋結論
- `get_queue_status`：查 Deriver 是否處理完

---

## Claude Code Plugin 整合

### 安裝步驟

1. 確認已安裝 [Bun](https://bun.sh)
2. 設定環境變數（PowerShell）：
   ```powershell
   $env:HONCHO_API_KEY = "hch-placeholder"
   $env:HONCHO_PEER_NAME = $env:USERNAME
   ```
3. 在 Claude Code 內執行：
   ```
   /plugin marketplace add plastic-labs/claude-honcho
   /plugin install honcho@honcho
   ```
4. 重啟 Claude Code
5. （選填）執行 `/honcho:interview` 建立個人偏好

### Plugin 功能

- 每次 session 開始自動載入記憶
- 每次對話後自動寫入 Honcho
- Git 感知：自動偵測 branch 切換
- Session strategy：`per-directory`（預設）/ `git-branch` / `chat-instance`
- 可連結多個工具 workspace（Claude Code ↔ Cursor）

### 設定檔位置

`~/.honcho/config.json`（Windows: `%USERPROFILE%\.honcho\config.json`）

```jsonc
{
  "apiKey": "hch-placeholder",
  "peerName": "YourName",
  "hosts": {
    "claude_code": {
      "workspace": "claude_code",
      "aiPeer": "claude"
    }
  },
  "sessionStrategy": "per-directory",
  "endpoint": {
    "environment": "production"
    // 若用 self-host: "baseUrl": "http://localhost:8000/v3"
  }
}
```

### 使用 Self-hosted Honcho

```json
{
  "endpoint": {
    "environment": "local"
  }
}
```
或
```json
{
  "endpoint": {
    "baseUrl": "http://your-server:8000/v3"
  }
}
```

---

## OpenClaw 整合

### 安裝（需先有 OpenClaw）

```bash
openclaw plugins install @honcho-ai/openclaw-honcho
openclaw honcho setup
openclaw gateway --force
```

`openclaw honcho setup` 會提示輸入 API key，並可遷移舊的記憶檔案（`USER.md`、`MEMORY.md` 等）。

### Self-hosted 設定

```bash
openclaw honcho setup
# 輸入時：API key 留空，Base URL 設為 http://localhost:8000
```

### OpenClaw 特有功能

- **Dual Peer Model**：使用者和 AI 各有獨立 representation
- **Multi-agent support**：子 agent 繼承父 agent 的 observer 設定
- **Platform metadata 過濾**：自動移除 WhatsApp/Telegram 等平台 metadata，只存有意義的對話內容

---

## 驗證整合是否真的接通

### MCP 驗證

設定完重啟後，對 AI 說：
> "What do you know about me?"

首次不會有什麼，但幾次對話後，問同一個問題，應該看到越來越豐富的回答。

### Claude Code Plugin 驗證

```bash
/honcho:status
```

應該顯示連線狀態和目前 workspace / session 資訊。

### 常見 MCP 問題

| 問題 | 解法 |
|------|------|
| 工具不顯示 | 完全重啟 client（不是 reload） |
| Authorization error | 確認 key 以 `hch-` 開頭，到 app.honcho.dev 驗證 |
| `npx` not found | 安裝 Node.js |
| "No personalization insights" | 正常，需要幾次對話後才有記憶 |

---

## 整合評估結論

- **MCP 整合**：真實可用，設定 5 分鐘內完成，立即有工具可呼叫
- **Claude Code Plugin**：真實可用，有自動記憶注入和 git 感知，需要 Bun
- **OpenClaw 整合**：真實可用，是最深度的整合（自動寫入 + 工具查詢 + 多 agent）
- **Self-hosted + 整合**：可行，只需改 `endpoint.baseUrl` 或 `baseUrl` 指向本機
