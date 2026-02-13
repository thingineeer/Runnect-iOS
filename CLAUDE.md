# Runnect-iOS

## 프로젝트 개요
- **앱 이름**: Runnect (러넥트) — 러닝과 일상을 연결하는 달리기 앱
- **플랫폼**: iOS (UIKit)
- **언어**: Swift 5.9
- **최소 타겟**: iOS 17.0
- **Xcode**: 16.0
- **패키지 관리**: CocoaPods
- **앱스토어**: 배포 중

## 주요 라이브러리
| 라이브러리 | 버전 | 용도 |
|-----------|------|------|
| Moya | 15.0.0 | 네트워킹 |
| SnapKit | 5.6.0 | Auto Layout |
| Then | 3.0.0 | UI 편의 |
| Kingfisher | 7.12.0 | 이미지 로딩 |
| NMapsMap | 3.17.0 | 네이버 지도 SDK |
| Google-Mobile-Ads-SDK | - | AdMob 광고 |
| FirebaseAnalytics | - | 애널리틱스 |

## 브랜치 전략
- **메인 브랜치**: `develop`
- **Feature 브랜치**: `feature/v{버전}-{설명}`
- **Fix 브랜치**: `fix/v{버전}-{설명}`
- **Chore 브랜치**: `chore/v{버전}-{설명}`
- **PR 대상**: 본체 레포 `Runnect/Runnect-iOS` → `develop`
- **포크**: `thingineeer/Runnect-iOS`
- **머지 후**: 로컬 + 리모트 브랜치 삭제

## 커밋 컨벤션
- **형식**: `<type>: <한국어 명사형 제목>`
- **타입**: feat, fix, refactor, style, docs, chore, test
- **제목**: 한국어, 50자 이내, 명사형
- **본문**: `-` 불릿 포인트로 how 설명
- **Author**: `thingineeer <dlaudwls1203@gmail.com>`
- **금지**: Co-Authored-By: Claude, Generated with Claude Code 등 AI 관련 표기 절대 금지

## PR 컨벤션
- **제목 형식**: `[Prefix] - 한국어 제목`
- **Prefix**: Feat, Fix, Refactor, Style, Docs, Chore, Test (첫글자 대문자)
- **예시**: `[Feat] - 코스 발견 성능 최적화 및 UX 개선`
- **Assignee**: 항상 `--assignee @me` (thingineeer) 지정
- **성과 기록**: 빌드 시간 단축, 코드 라인 수 변화, 성능 수치 등 측정 가능한 데이터는 PR 본문에 반드시 포함
- **Labels**: PR prefix에 맞는 라벨 + `명진😼` 항상 추가 (Feat, Fix, Refactor, Chore, Del, UX, Setting, Docs 등)
- **본문 템플릿** (`.github/PULL_REQUEST_TEMPLATE.md`):
  - 🌱 작업한 내용
  - 🌱 PR Point
  - 📸 스크린샷
  - 📮 관련 이슈

## 프로젝트 구조
```
Runnect-iOS/
├── Runnect-iOS/
│   ├── Presentation/          # 화면별 UI (VC, View, Cell)
│   │   ├── CourseDiscovery/   # 코스 발견
│   │   ├── CourseDrawing/     # 코스 그리기
│   │   ├── CourseStorage/     # 보관함
│   │   └── MyPage/           # 마이페이지
│   ├── Network/               # API 통신 (Moya)
│   ├── Global/                # 공통 유틸, 익스텐션
│   └── Resource/              # 에셋, 폰트
├── .github/                   # PR 템플릿, 워크플로우
└── Podfile                    # CocoaPods 의존성
```

## 배포 (Fastlane)
- `fastlane release version:X.X.X` — 빌드 + App Store 업로드
- `fastlane submit_review version:X.X.X` — 심사 제출 (바이너리 업로드 없이)
- `fastlane update_metadata version:X.X.X` — 메타데이터만 수정 (심사 중이면 자동 취소 후 재제출)
- `fastlane beta version:X.X.X` — TestFlight 배포
- **주의**: `bundle exec` 사용 불가 (bundler 버전 이슈) → `fastlane` 직접 실행
- **주의**: `fastlane/metadata/` 가 gitignored → `git add -f` 필요
- **코드 서명**: match 대신 자동 프로비저닝 (`update_code_signing_settings`) 사용

## 최신 릴리즈
- **현재 버전**: v2.4.1 (App Store 심사 제출됨)
- **iOS 버전 참고**: iOS 18 다음이 iOS 26 (19~25 없음)
