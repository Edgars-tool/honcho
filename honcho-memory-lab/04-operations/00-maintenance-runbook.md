# 00 — 維運 Runbook

> 日常、每週、每月維運流程

---

## 每日檢查（5 分鐘）

```powershell
# 一鍵執行每日檢查
# 1. Container 狀態
docker compose ps

# 2. Health check
Invoke-RestMethod -Uri "http://localhost:8000/health"

# 3. API 功能（DB 連線）
Invoke-RestMethod `
    -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST -ContentType "application/json" `
    -Body '{"name": "daily-check"}'

# 4. Deriver 最近 log
docker compose logs deriver --tail 20 --since 1h

# 5. 錯誤掃描
docker compose logs api --tail 50 --since 1h | Select-String "error|exception|critical" -CaseSensitive:$false
```

**判斷標準**：
- ✅ 所有 container running
- ✅ `/health` 回傳 `ok`
- ✅ workspace 建立成功
- ✅ Deriver log 有 polling 字樣，無持續性 error

---

## 每週檢查（15 分鐘）

```powershell
# 1. 磁碟使用量
docker system df

# 2. Database 大小
docker compose exec database psql -U postgres -c "
SELECT
    pg_size_pretty(pg_database_size('postgres')) AS db_size,
    (SELECT count(*) FROM pg_stat_user_tables) AS table_count;
"

# 3. Log 錯誤統計（過去 7 天）
docker compose logs api --since 168h 2>&1 | `
    Select-String "error|exception" -CaseSensitive:$false | `
    Measure-Object -Line

# 4. Queue 積壓（抽查幾個 workspace）
# 需要 Python SDK
```

```python
# weekly_check.py
from honcho import Honcho

workspaces_to_check = ["your-workspace-1", "your-workspace-2"]

for ws_id in workspaces_to_check:
    honcho = Honcho(base_url="http://localhost:8000", workspace_id=ws_id)
    try:
        status = honcho.workspaces.get_queue_status(workspace_id=ws_id)
        print(f"{ws_id}: pending={getattr(status, 'pending', '?')}")
    except Exception as e:
        print(f"{ws_id}: 查詢失敗 {e}")
```

---

## 升級前備份（升級前必做）

```powershell
# 備份資料庫（一行指令）
$date = Get-Date -Format "yyyyMMdd-HHmmss"
docker compose exec database pg_dump -U postgres postgres > "backup-honcho-$date.sql"
Write-Host "備份完成：backup-honcho-$date.sql"
```

---

## 升級後驗證

```powershell
# 升級後跑這個確認一切正常
Invoke-RestMethod -Uri "http://localhost:8000/health"

Invoke-RestMethod `
    -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST -ContentType "application/json" `
    -Body '{"name": "post-upgrade-check"}'

docker compose logs api --tail 20
docker compose logs deriver --tail 20
```

---

## 記憶品質抽查（每兩週）

```python
# memory_quality_check.py
from honcho import Honcho

WORKSPACE = "your-main-workspace"
PEER_ID = "your-test-peer"

honcho = Honcho(base_url="http://localhost:8000", workspace_id=WORKSPACE)

# 1. 查詢 conclusions 數量
conclusions = honcho.conclusions.list(
    workspace_id=WORKSPACE,
    peer_id=PEER_ID,
    limit=100
)
print(f"Conclusions 數量: {len(list(conclusions))}")

# 2. 測試 Dialectic 回答品質
response = honcho.peers.chat(
    workspace_id=WORKSPACE,
    peer_id=PEER_ID,
    query="Summarize what you know about this user in 5 bullet points"
)
print(f"\nDialectic 回答:\n{response}")
```

---

## 緊急停機/重啟

```powershell
# 優雅停機
docker compose stop

# 重新啟動
docker compose start

# 完整重啟（含重新 build）
docker compose down
docker compose up -d --build
```

---

## Runbook 速查卡

| 情況 | 指令 |
|------|------|
| Container 掛掉 | `docker compose up -d` |
| API 沒回應 | `docker compose restart api` |
| Deriver 停止 | `docker compose restart deriver` |
| 資料庫問題 | `docker compose logs database --tail 50` |
| Migration 沒跑 | `docker compose exec api uv run alembic upgrade head` |
| 備份 | `docker compose exec database pg_dump -U postgres postgres > backup.sql` |
| 完整重啟 | `docker compose down && docker compose up -d` |
