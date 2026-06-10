# 00 — 常見問題索引

> 快速查表：對應症狀找到詳細文件

---

## 症狀快查表

| 症狀 | 可能原因 | 詳細文件 |
|------|----------|----------|
| `docker compose up` 卡住/失敗 | build 錯誤、network 衝突 | `01-docker-build-fails.md` |
| API 回 500 | DB 未就緒、migration 未跑 | `02-database-redis-issues.md` |
| API 回 401/403 | Auth 設定錯誤或 key 無效 | `03-sdk-api-errors.md` |
| SDK `TypeError` / `ConnectionError` | baseUrl 設定錯、server 未起 | `03-sdk-api-errors.md` |
| 問 Dialectic 沒有個人化回應 | Deriver 未跑、記憶未建 | `04-memory-quality-issues.md` |
| Deriver 容器 crash loop | `ANTHROPIC_API_KEY` 缺失 | `01-docker-build-fails.md` |
| PostgreSQL 連線失敗 | DB URI 格式錯誤 | `02-database-redis-issues.md` |
| Redis 連線失敗 | Redis 服務未起 | `02-database-redis-issues.md` |
| MCP 工具沒出現在 client | 設定路徑錯誤、格式錯誤 | `../06-integration/03-mcp-integration.md` |
| Claude Code plugin 無法連線 | Bun 未安裝或 endpoint 錯 | `../06-integration/02-claude-code-integration.md` |

---

## 基本診斷流程

```
問題發生
    │
    ├─ 是 Docker 問題？
    │     └─ 看 01-docker-build-fails.md
    │
    ├─ 是 DB / Redis 問題？
    │     └─ 看 02-database-redis-issues.md
    │
    ├─ 是 API / SDK 錯誤？
    │     └─ 看 03-sdk-api-errors.md
    │
    └─ 記憶不準確？
          └─ 看 04-memory-quality-issues.md
```

---

## 快速健康確認（PowerShell）

```powershell
# 1. 容器狀態
docker compose ps

# 2. API 健康
Invoke-RestMethod -Uri http://localhost:8000/healthcheck

# 3. 最近錯誤
docker compose logs --tail=50 | Select-String "ERROR|Exception|Failed"
```

---

## 常見快速修復

```powershell
# 重啟所有服務
docker compose restart

# 重建並重啟（更新後使用）
docker compose down && docker compose up -d --build

# 清除卡住的 queue
docker compose exec database psql -U honcho -d honcho -c "DELETE FROM queue_items WHERE status = 'processing' AND created_at < NOW() - INTERVAL '1 hour';"

# 強制重跑 migration
docker compose exec api alembic upgrade head
```
