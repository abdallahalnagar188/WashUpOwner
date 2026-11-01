# WashUpOwner

Flutter app for car wash owners on Wash Up.

The app uses the same API as the vendor dashboard (`/api/v1/vendor/*`), so
permissions, discounts and audit rules stay on the server.

## Current state

Runs on mock data. `lib/core/data/mock_owner_repo.dart` implements
`OwnerRepo`; the API version replaces it in `lib/binding/app_binding.dart` once
the API documentation is ready. `AppConfig.useMockData` shows the mock data
banner.

- Bundle ID: `com.alnagar.washup.owner`
- Shared look: theme, fonts and base widgets come from the customer app.

## Run

```bash
flutter pub get
flutter run
```

Mock mode accepts any login details.

## Checks

```bash
flutter analyze
flutter test
```
