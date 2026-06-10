# 01 — OpenClaw 整合

> 官方支援，production ready

---

## 安裝

```bash
openclaw plugins install @honcho-ai/openclaw-honcho
openclaw honcho setup
openclaw gateway --force
```

`openclaw honcho setup` 互動式設定：
- 輸入 Honcho API key（雲端用）或留空（self-hosted 用）
- 設定 base URL（self-hosted 用 `http://localhost:8000`）
- 可遷移舊的記憶檔案

---

## Self-hosted 設定

```bash
openclaw honcho setup
# API key: 留空（直接 Enter）
# Base URL: http://localhost:8000
```

---

## 功能一覽

| 功能 | 說明 |
|------|------|
| 自動寫入 | 每次 AI 回應後，對話自動存入 Honcho |
| 工具查詢 | AI 可在對話中主動查詢 Honcho（`honcho_ask`、`honcho_context` 等） |
| Dual peer model | User 和 Agent 各有獨立 representation |
| 多 agent 支援 | subagent 繼承父 agent 的 observer 設定 |
| 舊記憶遷移 | 可遷移 `USER.md`、`MEMORY.md` 等舊格式 |

---

## AI 工具

| 工具 | 類型 | 說明 |
|------|------|------|
| `honcho_context` | 快速（無 LLM） | 取得 user 全局知識 |
| `honcho_search_conclusions` | 快速（無 LLM） | 語義搜尋結論 |
| `honcho_search_messages` | 快速（無 LLM） | 搜尋歷史訊息 |
| `honcho_ask` | 慢（LLM） | 問 Honcho 關於使用者的問題 |

---

## 更多資訊

- GitHub: https://github.com/plastic-labs/openclaw-honcho
- OpenClaw 官方文件: https://docs.openclaw.ai/concepts/memory-honcho
- Honcho 官方文件: https://honcho.dev/docs/v3/guides/integrations/openclaw
