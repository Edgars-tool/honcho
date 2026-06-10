# 02 — Logs & Debugging

---

## 常用 Log 指令

```powershell
# API server 最近 50 行
docker compose logs api --tail 50

# Deriver 最近 50 行
docker compose logs deriver --tail 50

# 即時追蹤 API log（-f = follow）
docker compose logs api -f

# 過去 1 小時的 error
docker compose logs api --since 1h | Select-String "error|exception" -CaseSensitive:$false

# 所有 service 同時
docker compose logs --tail 30
```

---

## 關鍵 Log 字樣

| 字樣 | 出現在哪 | 意義 |
|------|----------|------|
| `Application startup complete` | API | 啟動成功 |
| `polling` | Deriver | 正在等待 queue（正常） |
| `processing` | Deriver | 正在處理 message |
| `Finished` | Deriver | 一批處理完成 |
| `Missing client for` | API/Deriver | LLM API key 未設定 |
| `relation does not exist` | API | Migration 沒跑 |
| `Connection refused` | 任何 | 服務沒啟動或 port 錯誤 |
| `pgvector` extension | DB | pgvector 需要安裝 |

---

## 定位問題的快速流程

```powershell
# Step 1: 確認所有 container 在跑
docker compose ps

# Step 2: 看最近的 API 錯誤
docker compose logs api --tail 50 | Select-String "error|exception|traceback" -CaseSensitive:$false

# Step 3: 看 Deriver 狀態
docker compose logs deriver --tail 30

# Step 4: 測試 DB 連線
Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST -ContentType "application/json" `
    -Body '{"name": "debug-test"}'
```

---

## 進入 Container 除錯

```powershell
# 進入 API container
docker compose exec api bash

# 進入 DB container 跑 SQL
docker compose exec database psql -U postgres

# 在 DB 裡確認 table 存在
\dt

# 查 migration 狀態
docker compose exec api uv run alembic current
```

---

## Log Level 調整

```
# .env
LOG_LEVEL=DEBUG  # 更詳細的 log
```

重啟後生效：
```powershell
docker compose restart api deriver
```
