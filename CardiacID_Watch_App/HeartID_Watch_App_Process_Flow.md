# HeartID Watch App - Process Flow

## Overview
HeartID is a biometric authentication system that uses heart rate patterns captured from Apple Watch for secure user identification.

## Application Architecture

### Core Components
- **AuthenticationService**: Manages user enrollment and authentication
- **HealthKitService**: Interfaces with Apple Watch heart rate sensors
- **DataManager**: Handles secure storage of biometric templates
- **BackgroundTaskService**: Manages background operations

---

## User Journey Flow

### 1. Initial Launch
```
App Launch
    ↓
Landing Screen (5 seconds)
    ├── HeartID Logo Animation
    ├── Version Display (V0.3)
    ├── "Biometric Authentication" tagline
    └── Loading indicator
    ↓
Check Enrollment Status
    ├── Enrolled → Main Menu (Tab 1)
    └── Not Enrolled → Enrollment Flow
```

### 2. Enrollment Process (First Time Users)

#### Step 1: Welcome
```
Welcome Screen
    ├── Heart icon
    ├── "Welcome to HeartID"
    └── Process overview explanation
    ↓
[Next] button
```

#### Step 2: Instructions
```
Instructions Screen
    ├── Hand gesture icon
    ├── "How it Works" title
    └── 4-step process:
        1. Place finger on heart rate sensor
        2. Hold still for 30 seconds
        3. Capture unique heart pattern
        4. Use for secure authentication
    ↓
[Next] button
```

#### Step 3: Heart Pattern Capture
```
Capture Screen
    ├── Animated heart icon (pulsing during capture)
    ├── Status: "Ready to Capture" → "Capturing Heart Pattern..."
    ├── 30-second countdown timer
    ├── Progress bar (0-100%)
    └── Real-time heart rate sampling
    ↓
Automatic progression when complete
```

#### Step 4: Completion
```
Processing Screen
    ├── Clock icon → Checkmark icon (success)
    ├── "Processing..." → "Enrollment Complete!"
    ├── Success message
    └── Auto-complete after 2 seconds
    ↓
Main Menu
```

### 3. Main Application Tabs

```
TabView Navigation (Page-based, no indicators)
    ├── Tab 0: Landing View
    ├── Tab 1: Menu View (Primary)
    ├── Tab 2: Enroll View (Re-enrollment)
    ├── Tab 3: Authenticate View
    └── Tab 4: Settings View
```

---

## Technical Process Flow

### Enrollment Process
```
1. User Interaction
   ├── Tap "Next" on Capture Step
   ↓
2. Data Capture (30 seconds)
   ├── Initialize heart rate monitoring
   ├── Sample at 0.1s intervals
   ├── Collect heart rate data points
   ├── Update progress (0-100%)
   └── Simulate real-time feedback
   ↓
3. Template Processing
   ├── Process collected samples
   ├── Generate biometric template
   ├── Secure storage via DataManager
   └── Update enrollment status
   ↓
4. Completion
   ├── Mark user as enrolled
   ├── Enable authentication features
   └── Navigate to main menu
```

### Authentication Process
```
1. Authentication Request
   ├── User selects authenticate
   ↓
2. Heart Rate Capture
   ├── Activate HealthKit monitoring
   ├── Capture current heart pattern
   ├── Real-time data collection
   ↓
3. Pattern Matching
   ├── Compare with stored template
   ├── Calculate similarity score
   ├── Apply threshold validation
   ↓
4. Result
   ├── Success → Grant access
   └── Failure → Retry or fallback
```

---

## State Management

### Application States
```
AppState
    ├── showLandingScreen: Bool
    ├── isUserEnrolled: Bool
    ├── showEnrollmentFlow: Bool
    ├── selectedTab: Int (0-4)
    └── Timer management for landing
```

### Enrollment States
```
EnrollmentState
    ├── currentStep: Int (0-3)
    ├── enrollmentProgress: Double (0.0-1.0)
    ├── isCapturing: Bool
    ├── captureProgress: Double (0.0-1.0)
    ├── heartRateSamples: [Double]
    └── showSuccess: Bool
```

---

## User Experience Features

### Animations & Feedback
- **Landing Screen**: Logo scale animation, content fade-in
- **Enrollment**: Progress indicators, pulsing heart during capture
- **Success States**: Spring animations for completion checkmarks
- **Buttons**: Scale feedback on press (0.95x scale)

### Navigation Patterns
- **Progressive Disclosure**: Step-by-step enrollment
- **Tab-based Main Navigation**: Page-style swiping
- **Automatic Transitions**: Timer-based landing screen
- **State Persistence**: Remembers enrollment status

### Error Handling
- **User Deletion**: Reset to initial state
- **Timer Management**: Proper cleanup on view disappear
- **Progress Validation**: Bounds checking for progress values
- **Graceful Fallbacks**: Default states for edge cases

---

## Integration Points

### iOS Companion App
- **Watch Connectivity**: Bi-directional communication
- **Status Synchronization**: Enrollment state sharing
- **Remote Management**: Settings and configuration

### System Integration
- **HealthKit**: Heart rate sensor access
- **Background Tasks**: Continuous monitoring
- **Secure Storage**: Biometric template protection
- **Notification Center**: State change broadcasts

---

## Security Considerations

### Data Protection
- **Local Storage**: Biometric templates stored securely
- **Template Processing**: On-device computation only
- **No Cloud Storage**: Privacy-first architecture
- **Encryption**: Secure data manager implementation

### Authentication Flow
- **Challenge-Response**: Secure verification process
- **Threshold-based**: Configurable similarity matching
- **Fallback Options**: Alternative authentication methods
- **Session Management**: Time-based access control

---

## Development Architecture

### SwiftUI Implementation
- **Declarative UI**: Modern Apple framework usage
- **State-driven**: Reactive user interface updates
- **Animation Integration**: Smooth transitions and feedback
- **Accessibility**: Dynamic type size support

### Service Architecture
- **Dependency Injection**: Environment object pattern
- **Separation of Concerns**: Modular service design
- **Protocol-based**: Testable and maintainable code
- **Combine Integration**: Reactive data flow

This process flow provides a comprehensive overview of the HeartID Watch App's functionality, user experience, and technical implementation suitable for sharing with stakeholders, developers, or documentation purposes.