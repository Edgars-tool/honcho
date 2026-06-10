# verify-honcho.ps1
# 自動驗證 Honcho 安裝健康狀態
# 用法：.\verify-honcho.ps1 [-BaseUrl "http://localhost:8000"]

param(
    [string]$BaseUrl = "http://localhost:8000"
)

$Passed = 0
$Failed = 0

function Check {
    param([string]$Name, [scriptblock]$Test)
    try {
        & $Test
        Write-Host "  ✓ $Name" -ForegroundColor Green
        $script:Passed++
    } catch {
        Write-Host "  ✗ $Name — $($_.Exception.Message)" -ForegroundColor Red
        $script:Failed++
    }
}

Write-Host "=== Honcho 健康檢查 ===" -ForegroundColor Cyan
Write-Host "Target: $BaseUrl"
Write-Host ""

# Layer 1: Docker containers
Write-Host "[ 容器狀態 ]" -ForegroundColor Yellow
Check "Docker 可用" {
    $null = docker version 2>&1
    if ($LASTEXITCODE -ne 0) { throw "Docker 未運行" }
}
Check "api 容器運行中" {
    $status = docker compose ps api --format json 2>&1 | ConvertFrom-Json
    if ($status.State -ne "running") { throw "api 容器狀態：$($status.State)" }
}
Check "deriver 容器運行中" {
    $status = docker compose ps deriver --format json 2>&1 | ConvertFrom-Json
    if ($status.State -ne "running") { throw "deriver 容器狀態：$($status.State)" }
}
Check "database 容器運行中" {
    $status = docker compose ps database --format json 2>&1 | ConvertFrom-Json
    if ($status.State -ne "running") { throw "database 容器狀態：$($status.State)" }
}
Check "redis 容器運行中" {
    $status = docker compose ps redis --format json 2>&1 | ConvertFrom-Json
    if ($status.State -ne "running") { throw "redis 容器狀態：$($status.State)" }
}

# Layer 2: API
Write-Host ""
Write-Host "[ API 健康 ]" -ForegroundColor Yellow
Check "healthcheck endpoint" {
    $r = Invoke-RestMethod -Uri "$BaseUrl/healthcheck" -TimeoutSec 5
    if ($r -ne "OK" -and $r.status -ne "ok") { throw "非預期回應：$r" }
}
Check "API 版本 endpoint" {
    $null = Invoke-RestMethod -Uri "$BaseUrl/v3" -TimeoutSec 5
}

# Layer 3: Database
Write-Host ""
Write-Host "[ 資料庫 ]" -ForegroundColor Yellow
Check "PostgreSQL 可連線" {
    $result = docker compose exec database psql -U honcho -d honcho -c "SELECT 1;" 2>&1
    if ($result -notmatch "1 row") { throw "DB 查詢失敗" }
}
Check "Redis 可連線" {
    $result = docker compose exec redis redis-cli ping 2>&1
    if ($result.Trim() -ne "PONG") { throw "Redis ping 失敗：$result" }
}

# Layer 4: Deriver queue
Write-Host ""
Write-Host "[ Queue 狀態 ]" -ForegroundColor Yellow
Check "Queue 無大量 pending 積壓" {
    $result = docker compose exec database psql -U honcho -d honcho -t -c `
        "SELECT COUNT(*) FROM queue_items WHERE status = 'pending';" 2>&1
    $count = [int]$result.Trim()
    if ($count -gt 100) { throw "Queue pending 積壓：$count 筆" }
}

Write-Host ""
Write-Host "=== 結果 ===" -ForegroundColor Cyan
Write-Host "通過：$Passed" -ForegroundColor Green
if ($Failed -gt 0) {
    Write-Host "失敗：$Failed" -ForegroundColor Red
    Write-Host ""
    Write-Host "建議查看：07-troubleshooting/00-common-issues.md" -ForegroundColor Yellow
} else {
    Write-Host "全部通過！Honcho 運行正常。" -ForegroundColor Green
}
