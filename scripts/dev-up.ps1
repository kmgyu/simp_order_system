# Docker Compose를 이용한 로컬 통합 개발 환경 원클릭 실행 스크립트
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " Capybara QR Order - Local Environment Starting... " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. 루트 .env 파일 확인
if (-not (Test-Path ".env")) {
    Write-Host "[INFO] .env 파일이 없으므로 .env.example을 복사하여 생성합니다." -ForegroundColor Yellow
    Copy-Item ".env.example" ".env"
}

# 2. Docker Compose 빌드 및 실행
Write-Host "[INFO] Docker Compose 빌드 및 백그라운드 실행을 시작합니다..." -ForegroundColor Green
docker compose up -d --build

# 3. 서비스 상태 및 접속 안내
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " 서비스 접속 안내:" -ForegroundColor Green
Write-Host " - Frontend (Vue 3):    http://localhost:8080" -ForegroundColor White
Write-Host " - Backend (Flask API): http://localhost:3000" -ForegroundColor White
Write-Host " - MySQL Database:      localhost:3306 (user: order_user)" -ForegroundColor White
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "로그 확인: docker compose logs -f" -ForegroundColor Yellow
Write-Host "중지:      docker compose down" -ForegroundColor Yellow
