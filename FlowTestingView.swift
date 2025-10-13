//
//  FlowTestingView.swift
//  HeartID Watch App
//
//  Comprehensive testing interface for enrollment and authentication flows
//

import SwiftUI

struct FlowTestingView: View {
    @StateObject private var flowTester = EnhancedFlowTester()
    @StateObject private var testHarness = ArchitectureTestHarness()
    @State private var selectedTest: TestType = .enrollment
    @State private var showingResults = false
    @State private var showingIntegrationTest = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView
                    
                    // Test Selection
                    testSelectionView
                    
                    // Status Card
                    statusCardView
                    
                    // Results Display
                    if flowTester.enrollmentResult != nil || flowTester.authenticationResult != nil {
                        resultsView
                    }
                    
                    // Test Actions
                    testActionsView
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Flow Testing")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Integration") {
                        showingIntegrationTest = true
                    }
                }
            }
        }
        .sheet(isPresented: $showingResults) {
            TestResultsDetailView(
                enrollmentResult: flowTester.enrollmentResult,
                authenticationResult: flowTester.authenticationResult,
                architectureResults: testHarness.testResults
            )
        }
        .sheet(isPresented: $showingIntegrationTest) {
            IntegrationTestView()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "stethoscope")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Flow Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Test enrollment and authentication flows end-to-end")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var testSelectionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Type")
                .font(.subheadline)
                .fontWeight(.medium)
            
            Picker("Test Type", selection: $selectedTest) {
                ForEach(TestType.allCases, id: \.self) { test in
                    Text(test.rawValue).tag(test)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }
    
    @ViewBuilder
    private var statusCardView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading) {
                    Text("Test Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(flowTester.testStatus)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            // Progress indicator if testing
            if flowTester.testStatus.contains("Testing") {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var resultsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Results")
                .font(.subheadline)
                .fontWeight(.medium)
            
            if let enrollmentResult = flowTester.enrollmentResult {
                EnrollmentResultCard(result: enrollmentResult)
            }
            
            if let authResult = flowTester.authenticationResult {
                AuthenticationResultCard(result: authResult)
            }
        }
    }
    
    @ViewBuilder
    private var testActionsView: some View {
        VStack(spacing: 12) {
            // Individual test buttons
            HStack(spacing: 12) {
                Button("Test Enrollment") {
                    runEnrollmentTest()
                }
                .buttonStyle(.borderedProminent)
                .disabled(flowTester.testStatus.contains("Testing"))
                
                Button("Test Authentication") {
                    runAuthenticationTest()
                }
                .buttonStyle(.bordered)
                .disabled(flowTester.testStatus.contains("Testing"))
            }
            
            // Results button
            if flowTester.enrollmentResult != nil || flowTester.authenticationResult != nil {
                Button("View Detailed Results") {
                    showingResults = true
                }
                .buttonStyle(.borderless)
                .foregroundColor(.blue)
            }
            
            // Clear results
            Button("Clear Results") {
                clearResults()
            }
            .buttonStyle(.borderless)
            .foregroundColor(.secondary)
            .disabled(flowTester.enrollmentResult == nil && flowTester.authenticationResult == nil)
        }
    }
    
    // MARK: - Actions
    
    private func runEnrollmentTest() {
        Task {
            await flowTester.testEnrollmentFlow()
        }
    }
    
    private func runAuthenticationTest() {
        Task {
            await flowTester.testAuthenticationFlow()
        }
    }
    
    private func runFullArchitectureTest() {
        Task {
            await testHarness.runArchitectureTests()
            showingResults = true
        }
    }
    
    private func showIntegrationTest() {
        showingIntegrationTest = true
    }
    
    private func clearResults() {
        flowTester.enrollmentResult = nil
        flowTester.authenticationResult = nil
        flowTester.testStatus = "Ready"
    }
}

// MARK: - Test Type

enum TestType: String, CaseIterable {
    case enrollment = "Enrollment"
    case authentication = "Authentication"
    case both = "Both"
}

// MARK: - Result Cards

struct EnrollmentResultCard: View {
    let result: EnrollmentTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.success ? .green : .red)
                
                Text("Enrollment Test")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(result.confidence > 0.7 ? .green : .orange)
            }
            
            if let error = result.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
            } else {
                Text("Enrollment completed successfully")
                    .font(.caption)
                    .foregroundColor(.green)
            }
            
            Text("Quality Score: \(String(format: "%.1f%%", result.confidence * 100))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(result.success ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

struct AuthenticationResultCard: View {
    let result: AuthenticationTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.result.iconName)
                    .foregroundColor(result.result.iconColor)
                
                Text("Authentication Test")
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text("\(Int(result.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(result.confidence > 0.7 ? .green : .orange)
            }
            
            Text(result.result.message)
                .font(.caption)
                .foregroundColor(result.result.isSuccessful ? .green : .orange)
            
            HStack {
                Text("Confidence: \(String(format: "%.1f%%", result.confidence * 100))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Time: \(String(format: "%.2fs", result.processingTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(result.result.backgroundColor)
        .cornerRadius(8)
    }
}

// MARK: - Test Results Detail View

struct TestResultsDetailView: View {
    let enrollmentResult: EnrollmentTestResult?
    let authenticationResult: AuthenticationTestResult?
    let architectureResults: [TestResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                if let enrollment = enrollmentResult {
                    Section("Enrollment Test") {
                        EnrollmentDetailRow(result: enrollment)
                    }
                }
                
                if let auth = authenticationResult {
                    Section("Authentication Test") {
                        AuthenticationDetailRow(result: auth)
                    }
                }
                
                if !architectureResults.isEmpty {
                    Section("Architecture Tests") {
                        ForEach(architectureResults.suffix(5), id: \.id) { result in
                            TestResultDetailRowView(result: result)
                        }
                    }
                }
                
                Section("Summary") {
                    TestSummaryRow(
                        enrollmentResult: enrollmentResult,
                        authenticationResult: authenticationResult,
                        architectureResults: architectureResults
                    )
                }
            }
            .navigationTitle("Test Results")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct EnrollmentDetailRow: View {
    let result: EnrollmentTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.success ? "✅ Success" : "❌ Failed")
                    .fontWeight(.medium)
                Spacer()
                Text("\(String(format: "%.1f%%", result.confidence * 100)) quality")
                    .foregroundColor(.secondary)
            }
            
            if let error = result.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Text("Completed: \(result.timestamp.formatted(date: .omitted, time: .shortened))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

struct AuthenticationDetailRow: View {
    let result: AuthenticationTestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(result.result.title)
                    .fontWeight(.medium)
                Spacer()
                Text("\(String(format: "%.1f%%", result.confidence * 100))")
                    .foregroundColor(.secondary)
            }
            
            Text(result.result.message)
                .font(.caption)
                .foregroundColor(result.result.isSuccessful ? .green : .orange)
            
            HStack {
                Text("Processing time: \(String(format: "%.3fs", result.processingTime))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("Completed: \(result.timestamp.formatted(date: .omitted, time: .shortened))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct TestSummaryRow: View {
    let enrollmentResult: EnrollmentTestResult?
    let authenticationResult: AuthenticationTestResult?
    let architectureResults: [TestResult]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Test Summary")
                .font(.headline)
                .fontWeight(.bold)
            
            if let enrollment = enrollmentResult {
                HStack {
                    Text("Enrollment:")
                    Spacer()
                    Text(enrollment.success ? "✅ Passed" : "❌ Failed")
                        .foregroundColor(enrollment.success ? .green : .red)
                }
            }
            
            if let auth = authenticationResult {
                HStack {
                    Text("Authentication:")
                    Spacer()
                    Text(auth.result.isSuccessful ? "✅ Passed" : "⚠️ Warning")
                        .foregroundColor(auth.result.isSuccessful ? .green : .orange)
                }
            }
            
            if !architectureResults.isEmpty {
                let passedCount = architectureResults.filter { $0.status == .passed }.count
                let totalCount = architectureResults.count
                let passRate = totalCount > 0 ? Double(passedCount) / Double(totalCount) * 100 : 0
                
                HStack {
                    Text("Architecture:")
                    Spacer()
                    Text("\(Int(passRate))% pass rate")
                        .foregroundColor(passRate >= 90 ? .green : passRate >= 70 ? .orange : .red)
                }
            }
        }
    }
}

// MARK: - Preview

struct FlowTestingView_Previews: PreviewProvider {
    static var previews: some View {
        FlowTestingView()
    }
}