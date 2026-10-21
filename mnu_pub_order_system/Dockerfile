FROM node:20-alpine

WORKDIR /app

# npm 의존성 설치
COPY package*.json ./
RUN npm install

# 소스코드 전체 복사
COPY . .

# Vue CLI 개발 서버 기본 포트
EXPOSE 8080

ENV HOST=0.0.0.0
ENV PORT=8080

CMD ["npm", "run", "serve"]
