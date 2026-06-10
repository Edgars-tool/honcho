# 02 — Claude Code 整合

> 官方支援，production ready

---

## 前置需求

- [Bun](https://bun.sh)：`curl -fsSL https://bun.sh/install | bash`（Linux/Mac）或 Windows 見 https://bun.sh
- Honcho API key：https://app.honcho.dev

---

## 安裝（PowerShell）

```powershell
# Step 1: 設定環境變數
$env:HONCHO_API_KEY = "hch-placeholder"
$env:HONCHO_PEER_NAME = $env:USERNAME

# Step 2: 在 Claude Code 內執行
# /plugin marketplace add plastic-labs/claude-honcho
# /plugin install honcho@honcho

# Step 3: 重啟 Claude Code
```

---

## 設定檔

路徑：`%USERPROFILE%\.honcho\config.json`

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
  }
}
```

### 使用 Self-hosted Honcho

```jsonc
{
  "apiKey": "hch-placeholder",
  "endpoint": {
    "baseUrl": "http://localhost:8000/v3"
  }
}
```

---

## 驗證

在 Claude Code 內執行：
```
/honcho:status
```

應看到連線狀態和當前 workspace/session 資訊。

---

## 功能

| 功能 | 說明 |
|------|------|
| 持久記憶 | 跨 session 記憶，context wipe 後仍存在 |
| Git 感知 | 自動偵測 branch 切換 |
| 自動記憶注入 | Session 開始時自動載入相關記憶 |
| 自動寫入 | 每次對話後自動存入 Honcho |
| Cross-tool | 可連結 Cursor workspace，共享記憶 |

## Slash Commands

| 指令 | 說明 |
|------|------|
| `/honcho:status` | 連線狀態 |
| `/honcho:config` | 互動式設定選單 |
| `/honcho:interview` | 建立個人偏好（推薦首次使用） |
| `/honcho:setup` | 初始設定精靈 |

---

## 更多資訊

- GitHub: https://github.com/plastic-labs/claude-honcho
- 官方文件: https://honcho.dev/docs/v3/guides/integrations/claude-code
