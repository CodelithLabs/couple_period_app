# Couple Period App

Production-ready Flutter application focused on cycle support, mood tracking, and partner-aware care.

## Phase 5 (Final) Production Plan

This final phase is focused on launch readiness for the first 1000 mobile users.

1. Stability and quality gates
- Enforce static analysis and automated tests on every push and pull request.
- Keep null-safe error handling across all Firebase-dependent surfaces.

2. Backend trust and observability
- Verify Firebase initialization and authenticated session health.
- Verify Firestore read and write access for core features.
- Use in-app backend diagnostics before each release candidate.

3. Release operations and rollout safety
- Maintain Firestore rules and indexes for production privacy and performance.
- Use staged rollout and monitor crash/error trends before 100% rollout.

4. Store and GitHub launch readiness
- Ensure CI is green, changelog is prepared, and release tags are published.
- Publish signed release artifacts only after backend diagnostics pass.

## Implemented in Phase 5

- Production Settings screen with backend diagnostics:
	- Firebase initialized check
	- Auth session check
	- Firestore profile read check
	- Cycle backend access check
	- Mood backend access check
	- Firestore write probe check
- GitHub Actions CI workflow for `flutter analyze` and `flutter test`
- Release checklist embedded in app settings for final QA

## Firebase Backend Validation

Run these before shipping:

1. Sign in with Google in a release candidate build.
2. Open Settings > Run Backend Check.
3. Confirm all checks show pass (warnings only when expected, such as empty feature data).
4. If any check fails, block release until fixed.

## Local Commands

```bash
flutter pub get
flutter analyze
flutter test
```

## GitHub CI

CI workflow path:

- `.github/workflows/flutter_ci.yml`

It runs on pushes to `main` / `master` and pull requests.

## Android Production Release

This project is configured to produce signed Android release builds.

### 1) Create your upload keystore (one-time, local)

```bash
keytool -genkeypair -v \
	-keystore android/upload-keystore.jks \
	-alias upload \
	-keyalg RSA -keysize 2048 -validity 10000
```

### 2) Create `android/key.properties` (local, never commit)

```properties
storeFile=upload-keystore.jks
storePassword=YOUR_KEYSTORE_PASSWORD
keyAlias=upload
keyPassword=YOUR_KEY_PASSWORD
```

### 3) Build signed production artifacts locally

```bash
flutter pub get
flutter build apk --release
# Optional for Play Console uploads:
# flutter build appbundle --release
```

Outputs:

- `build/app/outputs/flutter-apk/app-release.apk`

## GitHub Releases as Download Page

Tag pushes (`v*`) trigger `.github/workflows/android_release.yml`.
That workflow builds a signed Android release APK and publishes it to GitHub Releases.

Configure these repository secrets first:

- `ANDROID_KEYSTORE_BASE64` (base64 content of `upload-keystore.jks`)
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Example release flow:

```bash
git add .
git commit -m "release: production Android pipeline"
git tag v1.0.0
git push origin main
git push origin v1.0.0
```

After the workflow finishes, users can download the production APK from the GitHub release page for that tag.

## Final Launch Checklist (1000-user target)

- [ ] `flutter analyze` passes locally and in CI
- [ ] `flutter test` passes locally and in CI
- [ ] Firestore rules and indexes deployed
- [ ] Backend check from Settings passes on a real device
- [ ] Crash/error monitoring configured
- [ ] Signed Android/iOS production builds generated
- [ ] GitHub release tag and notes published