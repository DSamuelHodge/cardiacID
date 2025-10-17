# HeartID Watch App — Process Flow Specification

This document captures the system/process flow described in the project's `process_flow.html`. It converts the HTML visualization into a concise, developer-oriented specification suitable for planning, implementation, and testing.

## Overview
Enterprise-grade biometric authentication system for the HeartID Watch App. The system is composed of four primary phases: system initialization, enrollment, authentication, and result processing. Core services include AuthenticationService, HealthKitService, DataManager, and XenonXCalculator.

## Contents
- Phase 1 — System Initialization & Setup
- Phase 2 — Enrollment Process
- Phase 3 — Authentication Process
- Phase 4 — Result Processing & Action
- Security Features
- Testing Framework
- Production Success Metrics

---

## Phase 1 — System Initialization & Setup
Responsibilities:
- Initialize application and inject service dependencies.
- Prepare core services and singletons.
- Request and validate HealthKit permissions.
- Prepare analytics/processing components.

Key behaviors and components:
- Entry points: `HeartIDWatchApp.swift`, `HeartIDApp.swift` (iOS/watch targets).
- Singletons and managers: `DataManager.shared`, `AuthenticationService`, `HealthKitService`.
- XenonXCalculator initialization for pattern processing.
- HealthKit authorization flow with diagnostics and error handling.

Acceptance criteria:
- All core services initialize without runtime errors.
- HealthKit authorization prompts and successes handled gracefully.
- Service dependency injection is testable via `ArchitectureTestHarness`.

---

## Phase 2 — Enrollment Process
Responsibilities:
- Walk user through enrollment UI and multi-step capture.
- Capture high-quality heart-rate data and compute a biometric template.
- Validate sample count and quality before accepting enrollment.

Capture and validation requirements:
- Target capture duration: 8–10 seconds.
- Minimum sample count: 200 samples.
- Heart rate range validation: 40–200 BPM.
- Variability analysis: standard deviation expected ~2–30 BPM (configurable).
- Real-time quality scoring and automatic retry for low-quality captures.

Processing and storage:
- Feature extraction and pattern fingerprinting via `XenonXCalculator`.
- Template confidence scoring; templates only stored when meeting threshold.
- Secure template creation: AES encryption, Keychain integration (local only).

Acceptance criteria:
- Enrollment UI reports progress and quality feedback.
- Templates are only stored when confidence/quality thresholds are met.
- Enrollment flow can be exercised in `FlowTestingView` and `EnhancedFlowTester`.

---

## Phase 3 — Authentication Process
Responsibilities:
- Initiate live capture and compare against stored templates.
- Provide visual feedback, attempt tracking, and retry logic.
- Evaluate security level and make allow/deny decisions.

Capture and matching requirements:
- Capture duration: ~8 seconds.
- Same quality standards as enrollment (real-time quality assessment).
- Multi-algorithm comparison (time-domain, frequency-domain, statistical matching).
- Security thresholds (configurable):
  - Low: 60% (fast)
  - Medium: 75% (balanced)
  - High: 85% (secure)
  - Maximum: 90% (very strict)
- Target processing latency: < 0.5 seconds for pattern comparison.

Acceptance criteria:
- Authentication decisions are deterministic given the same inputs and thresholds.
- UI shows progress, current heart rate, and confidence/score.

---

## Phase 4 — Result Processing & Action
Possible results:
- Approved — match above threshold.
- Denied — mismatch or security violation.
- Retry — low quality or partial match.
- Error — system or data error.
- Pending — temporary processing state (must not persist).

Post-auth actions:
- Update last-auth timestamp and session state.
- Audit logging and event tracking for analytics and drift detection.
- Access control integrations: Bluetooth door locks, app unlocks, external systems.

Acceptance criteria:
- Results are logged and session state is updated atomically.
- Access control integrations respect approved/denied outcomes and fail safely.

---

## Security Features
- AES-256 encryption for biometric templates.
- Keychain integration for secure key and template storage.
- Local processing only; no biometric data leaves the device.
- Data integrity checks, tamper detection, and automatic purging on failure.

---

## Testing Framework
A four-tier testing approach documented in the codebase:
- Level 1 — Architecture Testing: `ArchitectureTestHarness` validates initialization and service wiring.
- Level 2 — Flow Testing: `EnhancedFlowTester` / `FlowTestingView` for end-to-end enrollment/authentication flows.
- Level 3 — Integration Testing: `IntegrationTest` and test runners to validate persistence and system workflows.
- Level 4 — Interactive Testing: in-app testing UI via `FlowTestingView`.

Test acceptance criteria should include automated coverage for enrollment edge cases, auth thresholds, and HealthKit permission failures.

---

## Production Success Metrics
- Architecture Test Pass Rate: >= 95%.
- Enrollment Flow Success: 100% for valid test vectors (goal).
- Authentication latency: < 0.5s for pattern comparison.
- System Reliability: >= 99% availability.
- Encryption: AES-256
- Testing: 4-tier testing framework in place.

---

## Next steps / Recommendations
- Add explicit configuration entries for thresholds and quality parameters in `AppConfiguration`.
- Add unit tests that mock `HealthKitService` to reliably exercise enrollment and auth logic.
- Create an automated job that runs `ArchitectureTestHarness` and `IntegrationTest` on PRs.
- Document APIs used for access control integrations (Bluetooth/NFC) with failure modes.

---

Document created from `process_flow.html` visualization on Oct 17, 2025.
