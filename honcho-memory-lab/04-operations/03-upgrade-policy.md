# 03 — 升級政策

---

## 升級前必做清單

```
[ ] 備份資料庫（見 01-backup-restore.md）
[ ] 記錄目前的版本（git log --oneline -5）
[ ] 確認 Migration 文件有無 breaking change
[ ] 通知使用者服務維護窗口（若有）
```

---

## 升級步驟（Docker 模式）

```powershell
# 一鍵複製貼上升級流程

# Step 1: 備份
$date = Get-Date -Format "yyyyMMdd-HHmmss"
docker compose exec database pg_dump -U postgres postgres > "backup-pre-upgrade-$date.sql"
Write-Host "備份完成：backup-pre-upgrade-$date.sql"

# Step 2: 拉取最新 code
git pull

# Step 3: 停止服務
docker compose down

# Step 4: 重新 build 並啟動
docker compose up -d --build

# Step 5: 確認 migration 跑完（Docker 會自動執行）
Start-Sleep -Seconds 15
docker compose logs api --tail 30 | Select-String "startup|migration|error"

# Step 6: 驗證
Invoke-RestMethod -Uri "http://localhost:8000/health"
Invoke-RestMethod -Uri "http://localhost:8000/v3/workspaces" `
    -Method POST -ContentType "application/json" `
    -Body '{"name": "post-upgrade-verify"}'

Write-Host "升級驗證完成"
```

---

## 升級後出問題：回退

```powershell
# 回退到備份
docker compose down

# 還原資料
Get-Content "backup-pre-upgrade-YYYYMMDD.sql" | `
    docker compose exec -T database psql -U postgres postgres

# 回退 git（如果 code 也需要回退）
git checkout <previous-commit-hash>

# 重新 build 舊版
docker compose up -d --build

Write-Host "回退完成"
```

---

## 確認升級版本

```powershell
# 目前 git commit
git log --oneline -3

# Migration 版本
docker compose exec api uv run alembic current
```

---

## 注意事項

- Honcho 從 source build，升級 = `git pull` + `docker compose up --build`
- Migration 在啟動時自動執行，不需要手動跑
- 若 migration 有 schema 變更，回退較複雜（需還原 DB）
- 建議維護一個「最後已知良好版本」的 commit hash
