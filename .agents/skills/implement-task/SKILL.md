---
name: implement-task
description: "Implements a scoped software change from user requirements, inspecting the repository first, then editing, testing, checking the diff and reporting results. Use for feature work, bug fixes and refactors."
---

# Implement Task Skill

## 1. 목적 및 적용 범위

기능 추가·버그 수정·리팩터링 요청을 **요구사항 → 조사 → 계획 → 구현 → 검증 → 보고** 단계로 수행한다. 반복 작업 프로세스이며, 상시 금지/안전 조건은 루트 `AGENTS.md`와 Rules를 따른다.

## 2. 실행 절차

### Step 1 — 요구사항 확인

- 사용자 요청을 재정리하고 완료 조건, 포함/제외 범위를 식별한다.
- 중요 정보가 부족하지만 현 코드에서 확인 가능한 경우 먼저 조사한다.
- 구현 선택에 따라 데이터 손실, 외부 비용, 호환성 단절이 발생할 수 있으면 **먼저 승인**을 받는다.

### Step 2 — 현 상태 조사

- `AGENTS.md`, `docs/PROJECT_CONTEXT.md`, 관련 Rules/코드/테스트/설정을 확인한다.
- 기존 패턴·엔트리포인트·테스트 명령·잠재적 영향 범위를 파악한다.
- 프로젝트에 없는 기술·명령·테이블·API를 가정하지 않는다.

### Step 3 — 최소 계획

- 변경 대상 파일, 구현 방법, 테스트 방법, 호환성 영향을 간략히 계획한다.
- 규모가 크면 독립적으로 검증 가능한 단위로 나눈다.
- 작업과 무관한 리팩터링이나 패키지 교체를 계획에 섞지 않는다.

### Step 4 — 구현

- 한 번에 작은 범위로 수정하고 기존 인터페이스를 최대한 유지한다.
- 오류·보안·데이터 정합성·이해 가능한 코드 스타일을 고려한다.
- 필요 시 관련 테스트, 환경 변수 예시, 문서를 같이 수정한다.

### Step 5 — 검증

- 실행 가능하고 관련성 있는 테스트/검사를 수행한다.
- 실패 시 원인 분석 후 수정, 관련 검증 재실행한다.
- `git diff`·`git diff --check`·파일 상태를 확인해 의도하지 않은 변경을 점검한다.
- 실행하지 못한 검증은 NOT RUN으로 기록한다.

### Step 6 — 결과 보고

아래 형식으로 보고한다.

```text
상태: DONE | DONE WITH LIMITATIONS | BLOCKED | IN PROGRESS
변경 요약:
- <요구사항 대비 실제 구현>
주요 파일:
- <경로: 변경 이유>
검증:
- <실제 실행 명령>: PASS/FAIL/NOT RUN
주의 및 후속:
- <남은 위험/제약/필요한 승인>
Git:
- <커밋/푸시가 요청된 경우에만 수행 결과>
```

## 3. 종료 게이트

- 완료 판정은 `docs/DEFINITION_OF_DONE.md`를 따른다.
- 명시적 요청이 없는 커밋/푸시/배포는 수행하지 않는다.
- 도구 오류·테스트 실패·불확실성을 숨기지 않는다.
