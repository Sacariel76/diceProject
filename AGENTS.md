# AGENTS.md

## Project reality
- This repo is a single Flutter app package (no monorepo/workspace tooling).
- Current app entrypoint is `lib/main.dart`; networking wrapper is `lib/services/websocket_service.dart`.
- The README architecture section (`models/`, `screens/`, `widgets/`, etc.) does not match the current codebase; verify structure from `lib/` before implementing features.

## Commands that matter
- Run dependency sync first: `flutter pub get`.
- Static checks: `flutter analyze`.
- Test all: `flutter test`.
- Test one file: `flutter test test/widget_test.dart`.

## Known verification quirks
- `flutter test` currently fails: `test/widget_test.dart` is the default counter test and does not match `MyApp`.
- `flutter analyze` currently reports `avoid_print` infos in `lib/services/websocket_service.dart`; treat as existing baseline unless task requires lint cleanup.

## Runtime/config gotchas
- WebSocket server URL is hardcoded in code (`ws://3.228.25.228:5000` in `lib/services/websocket_service.dart`); there is no env/config layer for endpoint switching.
- `TestSocketScreen` connects in `initState()`, so tests that pump `MyApp` will trigger socket setup unless mocked/refactored.

## Generated files
- Do not hand-edit generated plugin registrant files under `linux/flutter/`, `macos/Flutter/`, and `windows/flutter/`; update them only via Flutter tooling.
