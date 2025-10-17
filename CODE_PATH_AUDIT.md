# Code Path Audit — HeartID Watch App

Date: 2025-10-17
Author: Automated audit (converted from project artifacts)

This audit maps the primary active code paths in the repository (entry points, enrollment and authentication flows, service interactions), identifies test coverage points, and lists gaps and recommended fixes.

## High-level entry points
- Watch app: `CardiacID_Watch_App/HeartIDWatchApp.swift` and `CardiacID_Watch_App/HeartIDApp.swift` (iOS companion)
- iOS app: `CardiacID/CardiacIDApp.swift`
- Watch authentication UI: `CardiacID_Watch_App/Views/AuthenticateView.swift`
- Enrollment UI: `CardiacID_Watch_App/Views/EnrollView.swift` and `CardiacID/Views/EnrollmentView.swift`
- Testing harnesses: `ArchitectureTestHarness.swift`, `IntegrationTest.swift`, `CardiacID_Watch_App/Services/TestRunner.swift`, `CardiacID_Watch_App/Services/BiometricTestingFramework.swift`

## Core services and where they're used
- AuthenticationService / AuthenticationManager
  - Files: `CardiacID_Watch_App/Services/AuthenticationService.swift`, `CardiacID/Services/AuthenticationManager.swift`, `CardiacID_Watch_App/Services/AuthenticationManager.swift`
  - Used by: `AuthenticateView.swift`, `EnrollView.swift`, `EnhancedAuthenticationService.swift`.

- HealthKitService / BasicHealthKitService
  - Files: `CardiacID_Watch_App/Services/HealthKitService.swift`, `CardiacID_Watch_App/Models/BasicHealthKitService.swift`
  - Used by: enrollment capture views and authentication views to get heart rate samples.

- DataManager / EncryptionService / KeychainService
  - Files: `CardiacID_Watch_App/Services/DataManager.swift`, `CardiacID/Services/EncryptionService.swift`, `CardiacID/Services/KeychainService.swift`
  - Used for storing templates, keys, and secure artifacts.

- XenonXCalculator / HRVCalculator / NASACalculator
  - Files: `CardiacID_Watch_App/Services/XenonXCalculator.swift`, `CardiacID_Watch_App/Services/HRVCalculator.swift`, `CardiacID_Watch_App/Services/NASACalculator.swift`
  - Used by: `EnhancedBiometricValidation.swift`, `EnhancedAuthenticationService.swift`, enrollment processing.

- WatchConnectivityService
  - Files: `CardiacID/Services/WatchConnectivityService.swift`, `CardiacID_Watch_App/Services/WatchConnectivityService.swift`
  - Used for iOS/watch synchronization and potential enrollment/alerts.

## Enrollment flow — UI to service path
1. User launches `EnrollView` / `EnrollmentFlowView`.
2. UI triggers HealthKit capture via `HealthKitService`.
3. Raw samples routed to `EnhancedBiometricValidation` for quality scoring.
4. On pass, features extracted via `XenonXCalculator` and stored through `DataManager` after encryption by `EncryptionService`.
5. Key material handled by `KeychainService`.
6. UI shows success/failure and logs events via `DebugLogger` / analytics.

Files that implement enrollment UI and flow:
- `CardiacID_Watch_App/Views/EnrollView.swift`
- `CardiacID_Watch_App/Views/EnrollmentFlowView.swift`
- `CardiacID/Views/EnrollmentView.swift`
- Validation: `CardiacID_Watch_App/Services/EnhancedBiometricValidation.swift`
- Storage: `CardiacID_Watch_App/Services/DataManager.swift`

## Authentication flow — UI to service path
1. User opens `AuthenticateView.swift`.
2. UI starts HealthKit capture (same `HealthKitService`).
3. Captured data passed to `XenonXCalculator` and `AuthenticationService`.
4. AuthenticationService compares the live features vs stored templates and returns a result (`Approved`, `Denied`, `Retry`, `Error`, `Pending`).
5. On `Approved`, downstream access control integrations are invoked (e.g., `BluetoothDoorLockService`).

Files that implement authentication UI and flow:
- `CardiacID_Watch_App/Views/AuthenticateView.swift`
- `CardiacID/Views/AuthenticateView.swift` (watch vs iOS split)
- Matching logic: `CardiacID_Watch_App/Services/AuthenticationService.swift`, `CardiacID_Watch_App/Services/EnhancedAuthenticationService.swift`
- Access control: `CardiacID/Services/BluetoothDoorLockService.swift`, `CardiacID/Services/NFCService.swift`

## Test coverage and where tests map to code paths
- Architecture tests: `ArchitectureTestHarness.swift` — validates initialization and service wiring.
- Flow & Integration tests: `IntegrationTest.swift`, `CardiacID_Watch_App/Services/TestRunner.swift`, `CardiacID_Watch_AppTests/*`, and `CardiacID_Watch_AppTests/BiometricAlgorithmTests*.swift` — exercise algorithms and sample handling.
- HealthKit integration tests: `CardiacID_Watch_AppTests/HealthKitIntegrationTests.swift` — ensures capture interfaces behave correctly under simulated conditions.

Observed test mapping gaps:
- No explicit unit tests mocking `KeychainService` and `EncryptionService` for failure modes.
- Limited tests for access control adapters (Bluetooth door lock / NFC) — these should have mocks.
- Race and concurrency tests for DataManager (concurrent reads/writes of templates) appear absent.

## Risk & missing coverage
1. HealthKit permission denial flow: ensure UI and flow tests simulate denied permissions and verify retry/prompt behavior.
2. Template corruption or partial writes: add tests which simulate DataManager write failures and verify automatic purge and user-visible retries.
3. Threshold and parameterization: thresholds (60/75/85/90) are present in documentation but should be centralized in `AppConfiguration.swift` and covered by unit tests.
4. Serialization/backwards compatibility: template format changes must be versioned; no clear migration code detected.
5. Watch <> iPhone sync: conflicts or mismatched templates may cause silent failures — tests should simulate out-of-sync states.

## Quick file map for reviewers (high-value files)
- `CardiacID_Watch_App/Services/AuthenticationService.swift` — core auth logic
- `CardiacID_Watch_App/Services/EnhancedBiometricValidation.swift` — enrollment validation
- `CardiacID_Watch_App/Services/XenonXCalculator.swift` — feature extraction
- `CardiacID_Watch_App/Services/HealthKitService.swift` — sensor capture
- `CardiacID_Watch_App/Services/DataManager.swift` — secure storage
- `CardiacID/Services/EncryptionService.swift` — crypto primitives
- `CardiacID/Services/KeychainService.swift` — key storage
- `CardiacID_Watch_App/Views/EnrollView.swift` — enrollment UI
- `CardiacID_Watch_App/Views/AuthenticateView.swift` — authentication UI

## Recommendations / Next steps
1. Centralize thresholds and capture parameters in `CardiacID_Watch_App/Utils/AppConfiguration.swift` (or `CardiacID/Utils`) and reference them from services and tests.
2. Add unit tests that mock `HealthKitService`, `KeychainService`, and `DataManager` to verify failure modes.
3. Add integration tests that simulate device sync issues and template mismatches.
4. Add a migration strategy for template formats with a version field and a small compatibility test.
5. Add CI job to run architecture and integration tests on PRs.
6. Add smoke tests to verify HealthKit permission flows and user-visible messaging.

---

If you want, I can now:
- Implement step 1 (centralize thresholds) and update a couple of services to consume the config.
- Add unit tests for a targeted area (e.g., DataManager failure mode).
- Create a GitHub Actions workflow that runs architecture and integration tests.

Tell me which follow-up to perform and I'll proceed.