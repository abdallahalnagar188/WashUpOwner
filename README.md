# WashUpOwner

Flutter app for car wash owners on Wash Up.

The app uses the same API as the vendor dashboard (`/api/v1/vendor/*`), so
permissions, discounts and audit rules stay on the server.

## Current state

- API calls are in `lib/core/data/`. The API has no written documentation yet;
  `docs/api-notes.md` records what the dashboard calls.
- Bundle ID: `com.alnagar.washup.owner`
- iOS builds run from the Codemagic Workflow Editor, started by hand on `main`. Bump the build number in `pubspec.yaml` first. Android is built outside Codemagic.
- Shared look: theme, fonts and base widgets come from the customer app.

## Run

```bash
flutter pub get
flutter run
```

## Checks

```bash
flutter analyze
flutter test
```
