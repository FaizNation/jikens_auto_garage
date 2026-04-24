# Project Overview: jikens_auto_garage

`jikens_auto_garage` is a Flutter application intended for garage management. It is currently in its initial stages, based on the standard Flutter boilerplate.

## Technologies
- **Language:** Dart
- **Framework:** Flutter
- **Platform Support:** Android, iOS, Web, Windows, Linux, macOS.
- **Linting:** `flutter_lints` for maintaining code quality.
- **Database:** Firebase

## Project Structure
- `lib/`: Contains the main source code for the application.
  - `main.dart`: The entry point of the app.
- `test/`: Contains automated tests.
- `pubspec.yaml`: Manages dependencies and project metadata.
- `analysis_options.yaml`: Configures linting rules and static analysis.

## Building and Running

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed.
- Target device or emulator (Android, iOS, or desktop).

### Key Commands
- **Run the app:** `flutter run`
- **Install dependencies:** `flutter pub get`
- **Run tests:** `flutter test`
- **Analyze code:** `flutter analyze`
- **Build APK:** `flutter build apk` (Android)
- **Build iOS App:** `flutter build ios` (iOS)

## Development Conventions
- **Linting:** Adheres to the `package:flutter_lints/flutter.yaml` ruleset.
- **Formatting:** Use `flutter format .` to maintain consistent code style.
- **State Management:** Currently uses standard `StatefulWidget` (setState).
- **Architecture:** Standard Flutter project structure. As the project grows, consider adopting a more robust architecture like Provider, Bloc, or Riverpod.
- **Styling:** Follows Material Design 3 guidelines.
