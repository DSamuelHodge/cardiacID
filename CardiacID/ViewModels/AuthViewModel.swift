import Foundation
import Combine
import SwiftUI

/// ViewModel to handle user authentication state and interact with backend
class AuthViewModel: ObservableObject {
    // Authentication state
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authError: String?
    @Published var isLoading = false
    
    // Login attempt tracking
    @Published var loginAttemptTracker = LoginAttemptTracker()
    
    // References to services
    private let supabaseService = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to the published properties from SupabaseService
        supabaseService.$isAuthenticated
            .assign(to: &$isAuthenticated)
        
        supabaseService.$currentUser
            .assign(to: &$currentUser)
        
        // If we already have a user, immediately set as authenticated
        if supabaseService.currentUser != nil {
            isAuthenticated = true
        }
    }
    
    /// Sign in a user with email and password
    func signIn(email: String, password: String) {
        debugLog.auth("Attempting sign in for email: \(email)")
        
        // Check if user can attempt login (not locked out)
        guard loginAttemptTracker.canAttemptLogin() else {
            let timeRemaining = loginAttemptTracker.getFormattedTimeRemaining() ?? "unknown time"
            authError = "Account locked. Try again in \(timeRemaining)"
            isLoading = false // Ensure loading state is reset
            return
        }
        
        guard !email.isEmpty, !password.isEmpty else {
            debugLog.auth("Sign in failed - empty credentials")
            authError = "Email and password cannot be empty"
            isLoading = false // Ensure loading state is reset
            return
        }
        
        isLoading = true
        authError = nil
        
        debugLog.auth("Starting authentication process...")
        
        supabaseService.signIn(email: email, password: password)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                debugLog.auth("Authentication completion received")
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    debugLog.error("Sign in failed for user: \(email)", error: error)
                    
                    // Record failed attempt
                    self?.loginAttemptTracker.recordFailedAttempt()
                    
                    // Create user-friendly error message with attempt count
                    let remainingAttempts = self?.loginAttemptTracker.remainingAttempts ?? 0
                    if remainingAttempts > 0 {
                        self?.authError = "Login not found - \(remainingAttempts) attempts remaining"
                    } else {
                        let lockoutReason = self?.loginAttemptTracker.lockoutReason ?? "Account locked"
                        self?.authError = lockoutReason
                    }
                } else {
                    debugLog.auth("Authentication completed successfully")
                }
            }, receiveValue: { user in 
                debugLog.auth("Sign in successful for user: \(email) - User: \(String(describing: user.firstName)) \(String(describing: user.lastName))")
                
                // Record successful attempt (resets lockout)
                self.loginAttemptTracker.recordSuccessfulAttempt()
                
                // The currentUser and isAuthenticated will be updated via the publishers
            })
            .store(in: &cancellables)
    }
    
    /// Sign out the current user
    func signOut() {
        supabaseService.signOut()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            }, receiveValue: { _ in 
                // The currentUser and isAuthenticated will be updated via the publishers
            })
            .store(in: &cancellables)
    }
    
    /// Update the user's profile
    func updateUserProfile(name: String) {
        guard currentUser != nil else {
            authError = "Not signed in"
            return
        }
        
        isLoading = true
        authError = nil
        
        supabaseService.updateUserProfile(name: name, profileImage: nil)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.authError = error.localizedDescription
                }
            }, receiveValue: { _ in 
                // The currentUser will be updated via the publisher
            })
            .store(in: &cancellables)
    }
    
    /// Reset lockout state (for testing/debugging)
    func resetLockoutState() {
        loginAttemptTracker.resetLockoutState()
        print("🔓 AuthViewModel: Lockout state reset")
    }
}
