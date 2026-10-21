---
trigger: always_on
description: "Git branch naming, Conventional Commits headers and messages, commit hygiene, PR workflow and prohibited Git operations."
---

# Git 및 커밋 컨벤션

## 1. 목적 및 적용 범위

브랜치·커밋 메시지·PR을 일관되게 관리한다. 이 규칙은 **명시적으로 Git 작업을 요청받았을 때의 수행 방식**을 정할 뿐, AI에게 커밋/푸시 권한을 자동으로 부여하지 않는다.

## 2. 브랜치 규칙

### 2.1 기본 정책

- 기본 브랜치는 저장소에 설정된 브랜치를 따르며, 예시에서는 `main`을 사용한다.
- 안정화용 `develop`은 **프로젝트가 이미 채택한 경우에만** 사용한다. 새로 도입하지 않는다.
- 기존 저장소에 합의된 명명법이 있다면 충돌을 확인하고 변경 여부를 사용자와 합의한다.

### 2.2 이름 형식

```text
<type>/<short-description>
<type>/<issue-id>-<short-description>
```

- `type`: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `build`, `ci`, `hotfix` 중 하나.
- `issue-id`: 선택, 예: `123` 또는 `PROJ-123`(팀의 티켓 체계에 맞춘다).
- 설명: 영어 소문자·숫자·하이픈(`kebab-case`)만 사용. 공백, 한글, 밑줄을 사용하지 않는다.
- 하나의 브랜치에는 가능한 하나의 변경 목적만 포함한다.

| 목적 | 권장 이름 |
| --- | --- |
| 새 기능 | `feat/123-user-login` |
| 버그 수정 | `fix/session-timeout` |
| 코드 구조 개선 | `refactor/order-service` |
| 문서 개선 | `docs/api-guide` |
| 긴급 수정 | `hotfix/payment-retry` |

잘못된 예: `feature/로그인 기능`, `fix_everything`, `min_dev_01`, `test`.

## 3. 커밋 메시지 규칙 (Conventional Commits)

### 3.1 헤더 형식

```text
<type>(<scope>)!: <subject>
<type>: <subject>
```

- `type` 필수, `scope`와 `!` 선택.
- `<scope>`는 변경 모듈을 나타내는 영문 소문자 `kebab-case`를 권장한다 (`auth`, `order-api`, `db`).
- `!`는 하위 호환성을 깨는 변경(BREAKING CHANGE)일 때만 사용한다.
- `type` 허용 값: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- 콜론 뒤 공백 한 칸, 제목의 문장 끝 마침표는 생략한다.
- `subject`는 **무엇이 바뀌었는지 구체적으로** 쓰며, 가급적 헤더 전체를 72자 이내로 작성한다. 한글/영문 모두 허용하되 같은 저장소의 기존 스타일을 우선한다.

**허용 예**

```text
feat(auth): 이메일 로그인 기능 추가
fix(order): 중복 주문 생성 방지
refactor(api): 주문 검증 로직 분리
test(payment): 결제 실패 회귀 테스트 추가
docs: 로컬 실행 가이드 보완
feat(api)!: 주문 응답 필드 구조 변경
```

**금지 예**

```text
update
fix bug
feat: 기능 개발 완료
수정사항 반영
```

### 3.2 본문/꼬리말

- 변경 내용이 복잡하거나 맥락이 중요하면 제목 아래 **빈 줄**을 두고 `이유 / 주요 변경 / 영향`을 본문에 기록한다.
- 관련 이슈는 `Refs: #123`, 종료 시 `Closes: #123`을 쓸 수 있다.
- 하위 호환성을 깨는 변경은 본문 꼬리말에 `BREAKING CHANGE: ...`를 명시한다.

```text
fix(order): 결제 재시도로 인한 중복 주문 차단

동일 요청이 재전송되면 신규 주문이 생성되던 문제를 해결한다.
- 멱등성 키 중복 검증 추가
- 중복 요청 회귀 테스트 추가

Refs: #123
```

### 3.3 커밋 단위

- **MUST**: 가능하면 하나의 의도/동작 변경을 하나의 커밋으로 기록한다.
- **MUST**: 커밋 전 diff와 스테이징 파일 목록을 확인한다.
- **MUST NOT**: 무관한 포맷 전체 변경, 비밀 정보, 생성된 빌드 산출물, 로그 파일을 의도 없이 섞는다.
- **SHOULD**: 테스트 실패 상태 또는 미완료 작업이라면 이유를 명확히 알리고 완료된 커밋처럼 설명하지 않는다.

## 4. Pull Request 원칙

- PR 제목도 커밋 헤더 형식을 권장한다.
- PR 설명에는 목적, 주요 변경 사항, 테스트 결과, 영향 범위, 위험 및 롤백 방안을 포함한다.
- 가능한 작은 PR을 권장하되, 일관성 있는 기능 단위는 유지한다.
- 보호 브랜치로 직접 푸시하지 않는다. 저장소의 리뷰·머지·브랜치 보호 정책을 따른다.
- Squash merge 여부는 저장소 정책을 따른다. 에이전트가 임의로 변경하지 않는다.

## 5. Git 명령 안전 규칙

명시적 승인 없이 `git commit`, `git push`, `git reset --hard`, `git clean -fd`, `git rebase -i`, `git push --force`, 작업 브랜치 삭제를 실행하지 않는다. `git status`, `git diff`, `git diff --check` 등 읽기·검증 명령을 우선한다.

## 6. 검증 기준

- 브랜치명은 정규 형식과 부합하는가?
- 커밋 헤더는 `<type>(<scope>): <subject>` 또는 허용된 변형인가?
- diff에 의도하지 않은 파일이나 비밀 정보가 포함되지 않았는가?
- 커밋·푸시·머지 등 실제 수행 권한이 사용자의 요청으로 확인되었는가?
