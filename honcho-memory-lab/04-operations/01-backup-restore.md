# 01 — 備份與還原

---

## 備份（一鍵執行）

```powershell
# 完整備份腳本（一次複製貼上）
$date = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = "backup-honcho-$date.sql"

Write-Host "開始備份 Honcho 資料庫..."
docker compose -f "C:\path\to\honcho\docker-compose.yml" exec database `
    pg_dump -U postgres postgres > $backupFile

if ($LASTEXITCODE -eq 0) {
    $size = (Get-Item $backupFile).Length / 1MB
    Write-Host "✅ 備份完成：$backupFile ($([math]::Round($size, 2)) MB)"
} else {
    Write-Host "❌ 備份失敗"
}
```

---

## 定期備份（Windows 工作排程器）

```powershell
# 建立每日凌晨 2 點備份排程（一鍵執行）
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument '-NonInteractive -Command "cd C:\path\to\honcho; $date = Get-Date -Format yyyyMMdd-HHmmss; docker compose exec database pg_dump -U postgres postgres > D:\backups\honcho\backup-$date.sql"'

$trigger = New-ScheduledTaskTrigger -Daily -At "02:00"
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

Register-ScheduledTask `
    -TaskName "HonchoBackup" `
    -Action $action `
    -Trigger $trigger `
    -Principal $principal `
    -Description "每日 Honcho 資料庫備份"

Write-Host "✅ 備份排程已建立"
```

---

## 還原

⚠️ 還原會覆蓋現有資料，請確認備份檔正確再執行。

```powershell
# 還原（一鍵執行）
$backupFile = "backup-honcho-20240101-020000.sql"  # 改為實際備份檔名

Write-Host "開始還原...這會覆蓋現有資料"
$confirm = Read-Host "確認執行？(yes/no)"

if ($confirm -eq "yes") {
    # 先停止 API 和 Deriver（避免寫入衝突）
    docker compose stop api deriver
    
    # 還原資料
    Get-Content $backupFile | docker compose exec -T database psql -U postgres postgres
    
    # 重新啟動
    docker compose start api deriver
    
    Write-Host "✅ 還原完成，請驗證服務是否正常"
    Invoke-RestMethod -Uri "http://localhost:8000/health"
} else {
    Write-Host "取消"
}
```

---

## 備份驗證

```powershell
# 確認備份檔案有效
$backupFile = "backup-honcho-YYYYMMDD.sql"
$lines = (Get-Content $backupFile | Measure-Object -Line).Lines
Write-Host "備份行數：$lines"

# 確認備份包含重要表格
Select-String -Path $backupFile -Pattern "CREATE TABLE" | ForEach-Object { $_.Line }
```

---

## 備份策略建議

| 情境 | 建議頻率 | 保留天數 |
|------|----------|----------|
| 開發環境 | 每週一次 | 7 天 |
| 生產環境 | 每日 | 30 天 |
| 升級前 | 每次升級前 | 永久保留 |
