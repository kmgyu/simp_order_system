FROM python:3.11-slim

WORKDIR /app

# 필수 빌드 도구 및 라이브러리 설치
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    default-libmysqlclient-dev \
    pkg-config \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 파이썬 의존성 설치
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# 소스코드 복사
COPY . .

# Flask 서버 포트
EXPOSE 3000

ENV FLASK_ENV=development
ENV PYTHONUNBUFFERED=1

CMD ["python", "run.py"]
