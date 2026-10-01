# 모바일(Flutter) 실습 환경 확인 목록

마지막 점검: 2026-10-01 (Windows 11, Flutter 3.44.4 stable, Dart 3.12.2)

- [x] 작업 폴더 최상위에 `AGENTS.md`와 `docs/` 폴더가 존재하는지 확인했다.
- [x] 터미널에서 `flutter --version`을 실행했을 때 Flutter SDK 버전이 정상 출력된다.
- [ ] 터미널에서 `flutter doctor`를 실행하여 Android/iOS 툴체인 및 개발 환경에 중대한 오류가 없는지 확인했다. (미점검. Windows 환경이라 iOS 툴체인은 확인 불가)
- [x] 에뮬레이터(Android Emulator 또는 iOS Simulator) 또는 실기기가 `flutter devices` 목록에 정상 인식된다. (Android 에뮬레이터 실행 시 인식 확인. 에뮬레이터를 켜지 않으면 Chrome·Edge만 표시됨)
- [x] 프로젝트 의존성이 정상 설치된다. 확인 방법: 터미널에서 `flutter pub get`을 실행해 에러 없이 완료되는지 본다.
- [x] 단위 테스트 도구가 동작한다. 확인 방법: 터미널에서 `flutter test`를 실행해 테스트 러너가 정상 실행되는지 본다. (7개 통과)
- [x] 에뮬레이터 또는 실기기에서 기본 실행(`flutter run`)이 성공한다. (Android 에뮬레이터, C: 여유 공간 약 13GB 이상 필요. 화면 캡처가 검게 나오면 소프트웨어 그래픽 모드로 재시작)
- [ ] 모바일 마이크 권한 요청이 가능한지 점검했다. (Android: `AndroidManifest.xml` 내 `RECORD_AUDIO`, iOS: `Info.plist` 내 `NSMicrophoneUsageDescription` 설정 여부) — 아직 두 항목 모두 미설정
- [ ] 기기 로컬 파일 쓰기 및 외부 공유/다운로드(`permission_handler`, `share_plus` 등)가 지원되는 환경인지 확인했다. — 패키지 미도입
- [x] `docs/plan.md`와 `docs/prompt-design.md`에 모바일 요구사항(보관 주기 1~14일, 다운로드, 당일 수정 잠금, 전환 시각 21:00~09:00)이 최신화되어 있다.
- [x] 코드와 설정 파일에 개인정보, 인증 토큰, 비밀번호, API 키가 포함되지 않았는지 점검했다. (`lib`, `test`, `pubspec.yaml`, 플랫폼 설정 검색 결과 없음)
