//
//  TestRunnerView.swift
//  HeartID Watch App
//
//  Interactive test runner for architecture validation
//

import SwiftUI

struct TestRunnerView: View {
    @StateObject private var testHarness = ArchitectureTestHarness()
    @State private var showingTestDetails = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    headerView
                    
                    // Overall Status Card
                    statusCardView
                    
                    // Test Results
                    if !testHarness.testResults.isEmpty {
                        testResultsView
                    }
                    
                    // Run Test Button
                    if testHarness.overallStatus != .running {
                        Button(action: runTests) {
                            HStack {
                                Image(systemName: "play.circle.fill")
                                Text("Run Architecture Tests")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .cornerRadius(25)
                        }
                    }
                    
                    Spacer(minLength: 20)
                }
                .padding()
            }
            .navigationTitle("Architecture Tests")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Details") {
                        showingTestDetails = true
                    }
                    .disabled(testHarness.testResults.isEmpty)
                }
            }
        }
        .sheet(isPresented: $showingTestDetails) {
            TestDetailsView(results: testHarness.testResults)
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var headerView: some View {
        VStack(spacing: 8) {
            Image(systemName: "testtube.2")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Architecture Testing")
                .font(.headline)
                .fontWeight(.bold)
            
            Text("Comprehensive validation of enrollment and authentication flows")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    @ViewBuilder
    private var statusCardView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: testHarness.overallStatus.icon)
                    .foregroundColor(testHarness.overallStatus.color)
                
                VStack(alignment: .leading) {
                    Text("Overall Status")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text(testHarness.overallStatus.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if testHarness.overallStatus == .running {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if testHarness.overallStatus == .running {
                VStack(spacing: 4) {
                    Text("Current Test:")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(testHarness.currentTest)
                        .font(.caption)
                        .fontWeight(.medium)
                }
            }
            
            if !testHarness.testResults.isEmpty {
                Divider()
                
                HStack {
                    let passedCount = testHarness.testResults.filter { $0.status == .passed }.count
                    let totalCount = testHarness.testResults.count
                    
                    VStack {
                        Text("\(passedCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Passed")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        Text("\(totalCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("Total")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack {
                        let passRate = totalCount > 0 ? Double(passedCount) / Double(totalCount) * 100 : 0
                        Text("\(Int(passRate))%")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(passRate >= 90 ? .green : passRate >= 70 ? .orange : .red)
                        Text("Pass Rate")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    @ViewBuilder
    private var testResultsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Recent Test Results")
                .font(.subheadline)
                .fontWeight(.medium)
            
            LazyVStack(spacing: 8) {
                ForEach(testHarness.testResults.suffix(10).reversed(), id: \.id) { result in
                    TestResultRowView(result: result)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func runTests() {
        Task {
            await testHarness.runArchitectureTests()
        }
    }
}

// MARK: - Test Result Row View

struct TestResultRowView: View {
    let result: TestResult
    
    var body: some View {
        HStack {
            Image(systemName: result.status.icon)
                .foregroundColor(result.status.color)
                .frame(width: 16)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(result.message)
                    .font(.caption)
                    .lineLimit(2)
                
                Text(result.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(result.status.color.opacity(0.1))
        .cornerRadius(6)
    }
}

// MARK: - Test Details View

struct TestDetailsView: View {
    let results: [TestResult]
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List(results, id: \.id) { result in
                TestResultDetailRowView(result: result)
            }
            .navigationTitle("Test Details")
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

struct TestResultDetailRowView: View {
    let result: TestResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.status.icon)
                    .foregroundColor(result.status.color)
                
                Text(result.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Spacer()
                
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(result.message)
                .font(.body)
                .foregroundColor(.primary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct TestRunnerView_Previews: PreviewProvider {
    static var previews: some View {
        TestRunnerView()
    }
}