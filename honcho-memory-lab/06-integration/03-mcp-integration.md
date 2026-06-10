# 03 — MCP 整合

> 通用 MCP server，任何 MCP-compatible tool 都能用

---

## MCP Server URL

雲端版：`https://mcp.honcho.dev`

---

## 各 Client 設定

### Claude Code（一行指令）

```bash
claude mcp add honcho \
  --transport http \
  --url "https://mcp.honcho.dev" \
  --header "Authorization: Bearer hch-placeholder" \
  --header "X-Honcho-User-Name: YourName"
```

### Claude Desktop（Windows）

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

### Cursor

編輯 `%USERPROFILE%\.cursor\mcp.json`：

```json
{
  "mcpServers": {
    "honcho": {
      "url": "https://mcp.honcho.dev",
      "headers": {
        "Authorization": "Bearer hch-placeholder",
        "X-Honcho-User-Name": "YourName"
      }
    }
  }
}
```

---

## 使用 Self-hosted MCP（指向本機 Honcho）

缺資料：官方文件未提供 self-hosted MCP server 的啟動方式。
Honcho 主 repo 含 `mcp/` 目錄，詳情需參考：
https://github.com/plastic-labs/honcho/tree/main/mcp

目前已知的方式：將 Claude Code Plugin 設定改為 local endpoint：
```json
{ "endpoint": { "environment": "local" } }
```

---

## 可選 Headers

| Header | 必填 | 說明 |
|--------|------|------|
| `Authorization` | ✅ | `Bearer hch-your-key` |
| `X-Honcho-User-Name` | ✅ | 你的名字 |
| `X-Honcho-Assistant-Name` | 選填 | AI peer 名字（預設 "Assistant"） |
| `X-Honcho-Workspace-ID` | 選填 | 指定 workspace（預設 "default"） |

---

## 可用 MCP 工具

| 類別 | 工具 |
|------|------|
| Workspace | `inspect_workspace`, `list_workspaces`, `search`, `get_metadata` |
| Peers | `create_peer`, `chat`, `get_peer_card`, `get_representation` |
| Sessions | `create_session`, `add_messages_to_session`, `get_session_context` |
| Conclusions | `list_conclusions`, `query_conclusions`, `create_conclusions` |
| System | `get_queue_status`, `schedule_dream` |

---

## 驗證

設定完成、重啟 client 後：

```
你：What do you know about me?
```

首次可能空白。幾次對話後再問，應有個人化回答。

---

## 更多資訊

- 官方文件: https://honcho.dev/docs/v3/guides/integrations/mcp
- MCP instructions: https://raw.githubusercontent.com/plastic-labs/honcho/refs/heads/main/mcp/instructions.md
