# Docker Compose 개발 환경 중지 및 정리 스크립트
param (
    [switch]$Volumes = $false
)

Write-Host "[INFO] Docker Compose 환경을 중지합니다..." -ForegroundColor Yellow

if ($Volumes) {
    Write-Host "[WARN] 볼륨(DB 데이터)을 포함하여 삭제합니다." -ForegroundColor Red
    docker compose down -v
} else {
    docker compose down
}

Write-Host "[OK] 환경이 정리되었습니다." -ForegroundColor Green
