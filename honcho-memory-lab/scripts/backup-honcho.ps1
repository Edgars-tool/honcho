# backup-honcho.ps1
# 備份 Honcho PostgreSQL 資料庫
# 用法：.\backup-honcho.ps1 [-BackupDir "D:\backups\honcho"]

param(
    [string]$BackupDir = "D:\backups\honcho"
)

$Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupFile = Join-Path $BackupDir "honcho_backup_$Timestamp.sql"

# 確認備份目錄存在
New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null

Write-Host "開始備份 Honcho 資料庫..." -ForegroundColor Cyan
Write-Host "目標：$BackupFile"

# 確認 DB 容器運行中
$dbStatus = docker compose ps database --format json 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "錯誤：無法取得 database 容器狀態" -ForegroundColor Red
    exit 1
}

# 執行備份
docker compose exec -T database pg_dump `
    -U honcho `
    -d honcho `
    --format=plain `
    --no-password `
    | Out-File -FilePath $BackupFile -Encoding utf8

if ($LASTEXITCODE -eq 0 -and (Test-Path $BackupFile)) {
    $size = (Get-Item $BackupFile).Length / 1MB
    Write-Host "備份完成！" -ForegroundColor Green
    Write-Host "  檔案：$BackupFile"
    Write-Host "  大小：$([math]::Round($size, 2)) MB"
} else {
    Write-Host "備份失敗！請檢查 Docker 狀態。" -ForegroundColor Red
    exit 1
}

# 清理超過 30 天的備份
$CutoffDate = (Get-Date).AddDays(-30)
$OldFiles = Get-ChildItem -Path $BackupDir -Filter "honcho_backup_*.sql" |
    Where-Object { $_.LastWriteTime -lt $CutoffDate }

if ($OldFiles.Count -gt 0) {
    Write-Host ""
    Write-Host "清理 30 天前的備份：" -ForegroundColor Yellow
    foreach ($f in $OldFiles) {
        Remove-Item $f.FullName
        Write-Host "  刪除：$($f.Name)" -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host "還原指令（需要時執行）：" -ForegroundColor Cyan
Write-Host "  Get-Content '$BackupFile' | docker compose exec -T database psql -U honcho -d honcho"
