# setup-folders.ps1
# 在指定路徑建立 honcho-memory-lab 完整資料夾結構
# 用法：.\setup-folders.ps1 [-TargetRoot "D:\01_projects_staging"]

param(
    [string]$TargetRoot = "D:\01_projects_staging"
)

$ProjectName = "honcho-memory-lab"
$ProjectRoot = Join-Path $TargetRoot $ProjectName

Write-Host "建立專案資料夾結構：$ProjectRoot" -ForegroundColor Cyan

$Dirs = @(
    "01-learning",
    "02-install",
    "03-verification",
    "04-operations",
    "05-self-host-server",
    "06-integration",
    "07-troubleshooting",
    "notes",
    "scripts"
)

foreach ($dir in $Dirs) {
    $path = Join-Path $ProjectRoot $dir
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Write-Host "  ✓ $dir" -ForegroundColor Green
}

Write-Host ""
Write-Host "資料夾結構建立完成：$ProjectRoot" -ForegroundColor Cyan
Write-Host ""
Write-Host "下一步：" -ForegroundColor Yellow
Write-Host "  1. 複製本 lab 的文件到 $ProjectRoot"
Write-Host "  2. 根據 02-install/ 指引設定環境"
Write-Host "  3. 執行 .\verify-honcho.ps1 驗證安裝"
