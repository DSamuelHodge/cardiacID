import SwiftUI
import Combine

struct LoginView: View {
    @State private var email = ""
    @State private var password = ""
    @State private var isLoggingIn = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var isAuthenticated = false
    @State private var lockoutTimer: Timer?
    
    @StateObject private var authViewModel = AuthViewModel()
    private let colors = HeartIDColors()
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                colors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // Logo/Header
                    VStack(spacing: 16) {
                        Image(systemName: "heart.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 60, height: 60)
                            .foregroundColor(colors.accent)
                        
                        Text("HeartID")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(colors.text)
                        
                        Text("Secure your identity with your unique cardiac signature")
                            .font(.subheadline)
                            .foregroundColor(colors.text.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top, 30)
                    
                    // Form Fields
                    VStack(spacing: 20) {
                        // Email field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .foregroundColor(colors.text.opacity(0.8))
                            
                            TextField("", text: $email)
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(12)
                                .foregroundColor(colors.text)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .disableAutocorrection(true)
                        }
                        
                        // Password field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .foregroundColor(colors.text.opacity(0.8))
                            
                            SecureField("", text: $password)
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(12)
                                .foregroundColor(colors.text)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Login Button
                    Button(action: login) {
                        if isLoggingIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: colors.text))
                                .scaleEffect(1.0)
                        } else {
                            Text("Sign In")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(authViewModel.loginAttemptTracker.isLockedOut ? colors.surface : colors.accent)
                    .cornerRadius(12)
                    .padding(.horizontal, 30)
                    .disabled(isLoggingIn || authViewModel.loginAttemptTracker.isLockedOut)
                    
                    // Lockout Status
                    if authViewModel.loginAttemptTracker.isLockedOut {
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.red)
                                Text("Account Locked")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.red)
                            }
                            
                            if let timeRemaining = authViewModel.loginAttemptTracker.getFormattedTimeRemaining() {
                                Text("Try again in \(timeRemaining)")
                                    .font(.caption)
                                    .foregroundColor(colors.text.opacity(0.7))
                            }
                            
                            if let reason = authViewModel.loginAttemptTracker.lockoutReason {
                                Text(reason)
                                    .font(.caption2)
                                    .foregroundColor(colors.text.opacity(0.6))
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 30)
                    } else if authViewModel.loginAttemptTracker.remainingAttempts < 2 {
                        // Show remaining attempts warning
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("\(authViewModel.loginAttemptTracker.remainingAttempts) attempts remaining")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal, 30)
                    }
                    
                    Spacer()
                    
                    // Sign Up Option
                    HStack {
                        Text("Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(colors.text.opacity(0.7))
                        
                        Button(action: {
                            // Show sign up screen
                        }) {
                            Text("Sign Up")
                                .font(.subheadline)
                                .foregroundColor(colors.accent)
                        }
                    }
                    .padding(.bottom, 10)
                    
                    // Debug Reset Button (for testing)
                    Button(action: {
                        authViewModel.resetLockoutState()
                    }) {
                        Text("Reset Lockout (Debug)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.bottom, 20)
                }
            }
            .alert(isPresented: $showError) {
                Alert(
                    title: Text("Login Failed"),
                    message: Text(errorMessage ?? "An unknown error occurred"),
                    dismissButton: .default(Text("OK"))
                )
            }
            .fullScreenCover(isPresented: $isAuthenticated) {
                ContentView()
                    .environmentObject(authViewModel)
            }
        }
        .onReceive(authViewModel.$isAuthenticated) { isAuthenticated in
            self.isAuthenticated = isAuthenticated
        }
        .onReceive(authViewModel.$authError) { error in
            if let error = error {
                errorMessage = error
                showError = true
            }
        }
        .onReceive(authViewModel.$isLoading) { isLoading in
            isLoggingIn = isLoading
        }
        .onAppear {
            startLockoutTimer()
        }
        .onDisappear {
            stopLockoutTimer()
        }
    }
    
    private func login() {
        guard !email.isEmpty && !password.isEmpty else {
            errorMessage = "Please enter both email and password"
            showError = true
            return
        }
        
        isLoggingIn = true
        
        authViewModel.signIn(email: email, password: password)
    }
    
    private func startLockoutTimer() {
        lockoutTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            // Force UI update to refresh lockout status
            authViewModel.objectWillChange.send()
        }
    }
    
    private func stopLockoutTimer() {
        lockoutTimer?.invalidate()
        lockoutTimer = nil
    }
}


// MARK: - Preview
#Preview {
    LoginView()
        .preferredColorScheme(.dark)
}
