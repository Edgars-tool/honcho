# 錯誤紀錄

> 遇到的錯誤與解法，避免重複踩雷

---

## 格式

```
## [YYYY-MM-DD] 錯誤摘要
**錯誤訊息**：...
**發生情境**：...
**根本原因**：...
**解法**：...
**預防**：...
```

---

## 已知陷阱（建置階段發現）

### DB URI 格式問題

**錯誤訊息**：`sqlalchemy.exc.ArgumentError: Could not parse rfc1738 URL`

**根本原因**：使用 `postgresql://` 而非 `postgresql+psycopg://`

**解法**：改為 `postgresql+psycopg://honcho:honcho@database:5432/honcho`

**預防**：在 .env 加入注釋提醒格式

---

### pgvector extension 缺失

**錯誤訊息**：`ERROR: extension "vector" does not exist`

**根本原因**：docker-compose.yml 使用 `postgres:16` 而非 `pgvector/pgvector:pg16`

**解法**：改 image，`docker compose down -v && docker compose up -d --build`

**預防**：建置前確認 docker-compose.yml 使用 pgvector image

---

### TypeScript SDK 測試不能直接跑

**錯誤訊息**：`bun test` 立即失敗

**根本原因**：TS SDK 測試需要運行中的 Honcho server + DB + Redis

**解法**：從 monorepo root 用 `uv run pytest tests/ -k typescript`

**預防**：看 CLAUDE.md 的 SDK Testing 章節

---

## 自行填寫區域

| 日期 | 錯誤 | 解法 | 預防 |
|------|------|------|------|
| | | | |
