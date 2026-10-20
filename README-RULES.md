# Antigravity 개발 규칙 스타터 키트

> 문서 버전: 1.0.0 | 적용 대상: Antigravity를 활용하는 단일 저장소 또는 멀티레포의 개별 저장소 | 문서 언어: 한국어

## 1. 목적

AI 에이전트가 **동일한 코드 품질·Git 이력·변경 안전성** 기준으로 개발하도록 규칙을 정의한다. 이 세트는 프레임워크에 독립적이며 프로젝트마다 `docs/PROJECT_CONTEXT.md`부터 채운다.

- **MUST / MUST NOT**: 반드시 준수 / 금지. 예외가 필요하면 사용자 승인을 먼저 받는다.
- **SHOULD**: 원칙적으로 준수. 예외가 있다면 이유를 작업 결과에 기록한다.
- **MAY**: 필요에 따라 선택.
- `[작성 필요]`: 템플릿 필드. 프로젝트 정보를 조사하거나 사용자에게 확인하기 전에는 사실로 가정하지 않는다.

## 2. 파일 구조 및 역할

```text
<repository-root>/
├── AGENTS.md                            # 에이전트 최상위 행동 규칙 (항상 적용)
├── README-RULES.md                      # 이 파일: 설치·사용·규격 설명
├── .agents/
│   ├── rules/
│   │   ├── 10-git-conventions.md         # 브랜치·커밋·PR·Git 금지 동작
│   │   ├── 20-development-conventions.md # 개발·리팩터링·주석 컨벤션
│   │   ├── 30-testing-quality.md        # 테스트·검증 기준
│   │   ├── 40-security-data.md          # 보안·개인정보·위험 작업
│   │   └── 50-api-db-compatibility.md   # API/DB 변경 작업에만 자동 선택
│   └── skills/
│       ├── implement-task/SKILL.md      # 구현 단계별 수행 절차
│       └── review-change/SKILL.md      # 코드 리뷰 수행 절차
├── .github/
│   └── PULL_REQUEST_TEMPLATE.md         # GitHub PR 양식
└── docs/
    ├── PROJECT_CONTEXT.md              # 기술 스택·실행 명령·실제 현황 (우선 작성)
    ├── ARCHITECTURE.md                 # 아키텍처·의존성·변경 불가 조건
    ├── DEFINITION_OF_DONE.md           # 완료 및 검증 체크리스트
    ├── ADR_TEMPLATE.md                 # 주요 기술 결정 기록 템플릿
    └── RELEASE_CHECKLIST.md           # 배포 전후 점검 (배포 자동 승인 아님)
```

## 3. 도입 순서

1. 이 디렉터리의 **내용물**을 해당 Git 저장소 루트에 복사한다. 이미 `AGENTS.md`, `.agents/`, `.github/PULL_REQUEST_TEMPLATE.md`가 존재하면 **덮어쓰지 않고 수동 병합**한다.
2. `docs/PROJECT_CONTEXT.md`에 확인된 기술 스택, 실행/테스트 명령, 패키지 매니저, 저장소 구조를 작성한다. 모르면 `[작성 필요]`를 유지한다.
3. `docs/ARCHITECTURE.md`에 **실제로 존재하는 구성 요소**와 데이터 흐름만 기록한다.
4. `AGENTS.md`와 `.agents/rules/*.md`를 커밋하여 모든 기여자가 같은 규칙을 사용하게 한다.
5. Antigravity에서 작은 수정 작업을 요청하고, 규칙을 따르는지 확인한다. 규칙 파일 자체를 바꾼 경우에도 테스트한다.

> 기술 스택별 formatter, linter, test 명령은 **문서만으로 실행되거나 강제되지 않는다**. 실제 프로젝트의 설정 파일·Git hooks·CI에서 별도로 강제할 것을 권장한다.

## 4. 규칙의 적용 방식

| 종류 | 위치 | 로딩 특성 | 적합한 내용 |
| --- | --- | --- | --- |
| 최상위 지침 | `AGENTS.md` | 항상 적용 | 안전 규칙, 우선순위, 작업 기본 원칙 |
| 상시 Rules | `.agents/rules/*.md` + `trigger: always_on` | 항상 적용 | Git, 코딩, 테스트, 보안 원칙 |
| 조건부 Rules | `.agents/rules/*.md` + `trigger: model_decision` | 관련 작업에서 선택 | API/DB/마이그레이션 세부 규칙 |
| 반복 작업 Skills | `.agents/skills/<skill>/SKILL.md` | 작업 적합성 또는 명시적 호출에 따라 로드 | 구현·리뷰 프로세스 |
| 레퍼런스 문서 | `docs/*.md` | AGENTS/Rules/Skills에서 필요 시 참조 | 프로젝트의 실제 맥락과 상세 절차 |

Antigravity는 `.agents/rules/` 바로 아래의 Markdown 파일을 발견한다. 각 Rule 파일은 `trigger`가 있는 YAML frontmatter로 시작해야 한다. `AGENTS.md`에는 frontmatter를 넣지 않는다.

## 5. 문서 작성 표준

모든 가이드의 본문 순서는 가능한 범위에서 아래 순서를 따른다.

1. `# 문서명`: 역할이 명확한 한 줄 제목
2. `## 목적 및 적용 범위`: 적용 상황/제외 상황
3. `## 필수 규칙`: MUST/MUST NOT/SHOULD로 검증 가능한 행동 작성
4. `## 예시`: 올바른 예와 잘못된 예
5. `## 검증/완료 기준`: 작업 후 무엇을 확인할지
6. `## 관련 문서`: 상대 경로 링크(필요한 경우)

- 제목은 `#` 하나, 하위는 `##` → `###` 순서로 사용한다.
- 규칙 하나에는 가능하면 **하나의 행동**과 **하나의 이유**만 담는다.
- 숫자 제한은 실제로 지킬 수 있는 것만 사용한다. 언어별 코딩 스타일은 포매터가 우선한다.
- 바뀔 가능성이 높은 값(명령, 버전, URL, 접근 경로, 배포 환경)은 `PROJECT_CONTEXT.md`나 프로젝트 설정을 진실의 원천으로 삼는다.
- 문서가 코드와 모순되면 **독단적으로 사실을 정하지 말고 실제 코드/설정을 확인**한 후 문서를 수정하거나 질문한다.

## 6. 빠른 예시

```text
요청: 로그인 오류 수정. 관련 회귀 테스트를 추가하고 작업을 정리해줘.
결과: 변경 파일 요약 → 테스트 실행 결과 → 미검증 항목 → 위험/후속 조치
주의: 별도 요청이 없으면 commit/push/deploy하지 않는다.
```

## 7. 프로젝트별 추가 도입 권장

| 조건 | 추가 문서/설정 | 이유 |
| --- | --- | --- |
| 팀 인원이 늘어남 | `CONTRIBUTING.md`, CODEOWNERS | 리뷰 소유권·기여 프로세스 |
| 실서비스 운영 시작 | 실행 가능한 CI, 배포/롤백 Runbook, 모니터링 기준 | 문서만으로 장애를 막을 수 없음 |
| API 외부 공개 | OpenAPI 스펙/계약 테스트 | 코드와 계약의 불일치 방지 |
| DB 마이그레이션 증가 | 실제 DB별 마이그레이션 SOP | 잠금·데이터 정합성·복구 관리 |
| 개인정보·결제 취급 | 접근 통제·로그 보존·보안 검토 기준 | 규제/운영 위험 통제 |

## 8. 참고

- [Antigravity Rules 공식 문서](https://antigravity.google/docs/rules/)
- [Antigravity Agent Skills 공식 문서](https://antigravity.google/docs/skills/)
- [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/)

이 세트의 세부 규칙은 **권장 정책**이며 Antigravity 자체의 필수 기본값이 아니다. 프로젝트에 맞게 팀에서 합의하고 조정한다.
