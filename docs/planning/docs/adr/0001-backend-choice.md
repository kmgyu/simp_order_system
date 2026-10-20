# ADR-0001: 백엔드 기술 선택(Flask 유지 제안) — v0.2

- Status: **Proposed** (팀 수용 전)
- Date: 2026-10-14
- Owners: TBD

## Context
v0.1 작성 당시 공개된 프론트 저장소에서 BE 소스를 찾지 못했으나, v0.2에서 `Capybara-Clinic/capybara-qr-order`를 확보·정적 검토했다. 이 저장소에는 Flask 3.1.1, SQLAlchemy, MySQL 드라이버, 5개 Blueprint·7개 ORM 모델과 주문/캐셔/서빙 로직이 존재한다. 단, 주문 재고 미차감/취소 재고 복원, 인증 누락 등 P0 결함이 있다.

## Decision (proposal)
**기본안: Flask/SQLAlchemy/MySQL 유지 + 모듈러 모놀리스 정비.** 16주 목표는 실제 안정적인 주문 수직 기능/파일럿, 팀 개발·운영 경험이다. 기술 스택 전환은 해당 목표와 별개 위험이며 P0 완료 이후 선택적으로 추진.

## Alternatives
- Spring Boot/Java 전체 재구현: Java 채용 직무 학습 장점, 동작 구현·동시성·배포를 다시 검증해야 함.
- Flask 유지: 기능 재사용·빠른 실사용 장점, 팀의 Python 숙련도 및 서비스 계층 재설계 필요.
- 신 서버 부분 병행: 하나의 주문 업무를 둘로 분리하는 분산 일관성 비용이 높아 초기 비권장.

## Tradeoffs / 테스트
- 서비스 모듈화/pytest/CI/DB migration 도입으로 유지보수성·도메인 검증 보완.
- 실제 DB와 FE를 통합 구동하고 P0 실험을 완료해 Flask 유지 비용/안정성 평가.
- Spring 학습은 추후 계약·회귀 테스트가 있는 독립 재구현 비교 연구로 수행.

## Revisit trigger
동의한 팀의 Java 중심 구성, 유지보수 병목이 측정으로 확인, 목표 기업/도메인 명시와 학습 ROI, 2주 Spike에서 더 낮은 전환 비용 확인.

## Acceptance
결정일 / 참여자 / 시험 데이터/환경 / 확정안 / 반대안 / 비용 / 링크를 PR에 남기고 Accepted로 변경.
