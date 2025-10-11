import Foundation
import Combine

/// Manager for coordinating authentication services and managing authentication state
class AuthenticationManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var authenticationState: AuthenticationState = .idle
    @Published var currentUser: UserProfile?
    @Published var errorMessage: String?
    
    private let authenticationService: AuthenticationService
    private let healthKitService: HealthKitService
    private let dataManager: DataManager
    // SupabaseService not available in watch app
    private let backgroundTaskService: BackgroundTaskService
    private let bluetoothNFCService: BluetoothNFCService
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.authenticationService = AuthenticationService()
        self.healthKitService = HealthKitService()
        self.dataManager = DataManager()
        // Supabase service not available in watch app
        self.backgroundTaskService = BackgroundTaskService()
        self.bluetoothNFCService = BluetoothNFCService()
        
        setupServices()
        setupBindings()
    }
    
    // MARK: - Setup
    
    private func setupServices() {
        // Set up service dependencies
        // Supabase service not available in watch app
        
        // Load current user
        currentUser = dataManager.getUserProfile()
        isAuthenticated = currentUser?.isEnrolled ?? false
    }
    
    private func setupBindings() {
        // Bind authentication service state
        authenticationService.$isAuthenticated
            .sink { [weak self] value in
                DispatchQueue.main.async {
                    self?.isAuthenticated = value
                }
            }
            .store(in: &cancellables)
        
        authenticationService.$isUserEnrolled
            .sink { [weak self] isEnrolled in
                DispatchQueue.main.async {
                    self?.isAuthenticated = isEnrolled
                }
            }
            .store(in: &cancellables)
        
        // Bind error messages
        authenticationService.$errorMessage
            .sink { [weak self] value in
                DispatchQueue.main.async {
                    self?.errorMessage = value
                }
            }
            .store(in: &cancellables)
        
        healthKitService.$errorMessage
            .sink { [weak self] (error: String?) in
                DispatchQueue.main.async {
                    if let error = error {
                        self?.errorMessage = error
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Authentication Flow
    
    /// Start enrollment process
    func startEnrollment() {
        DispatchQueue.main.async {
            self.authenticationState = .enrolling
        }
        
        // Start heart rate capture using duration and completion handler
        healthKitService.startHeartRateCapture(duration: AppConfiguration.defaultCaptureDuration) { [weak self] samples, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.authenticationState = .error(error.localizedDescription)
                }
                return
            }
            let values = samples.map { $0.value }
            self.completeEnrollment(with: values)
        }
    }
    
    /// Complete enrollment with heart rate samples
    private func completeEnrollment(with samples: [Double]) {
        let heartRateData = samples
        // Validate data
        guard healthKitService.validateHeartRateData(samples) else {
            DispatchQueue.main.async {
                self.authenticationState = .error("Invalid heart rate data")
            }
            return
        }
        
        // Complete enrollment
        let success = authenticationService.completeEnrollment(with: heartRateData)
        
        DispatchQueue.main.async {
            if success {
                self.authenticationState = .enrolled
                self.currentUser = self.dataManager.getUserProfile()
            } else {
                self.authenticationState = .error(self.authenticationService.errorMessage ?? "Enrollment failed")
            }
        }
    }
    
    /// Start authentication process
    func startAuthentication() {
        guard authenticationService.isUserEnrolled else {
            DispatchQueue.main.async {
                self.authenticationState = .error("User not enrolled")
            }
            return
        }
        
        DispatchQueue.main.async {
            self.authenticationState = .authenticating
        }
        
        // Start heart rate capture using duration and completion handler
        healthKitService.startHeartRateCapture(duration: AppConfiguration.defaultCaptureDuration) { [weak self] samples, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.authenticationState = .error(error.localizedDescription)
                }
                return
            }
            let values = samples.map { $0.value }
            self.completeAuthentication(with: values)
        }
    }
    
    /// Complete authentication with heart rate samples
    private func completeAuthentication(with samples: [Double]) {
        let heartRateData = samples
        // Validate data
        guard healthKitService.validateHeartRateData(samples) else {
            DispatchQueue.main.async {
                self.authenticationState = .error("Invalid heart rate data")
            }
            return
        }
        
        // Complete authentication
        let result = authenticationService.completeAuthentication(with: heartRateData)
        
        DispatchQueue.main.async {
            switch result {
            case .approved:
                self.authenticationState = .authenticated
            case .retry:
                self.authenticationState = .retryRequired
            case .denied:
                self.authenticationState = .error("Authentication failed")
            case .error(let message):
                self.authenticationState = .error(message)
            case .pending:
                self.authenticationState = .retryRequired
            }
        }
    }
    
    /// Retry authentication
    func retryAuthentication() {
        startAuthentication()
    }
    
    /// Logout user
    func logout() {
        authenticationService.endCurrentSession()
        DispatchQueue.main.async {
            self.authenticationState = .idle
            self.isAuthenticated = false
        }
    }
    
    // MARK: - Background Authentication
    
    /// Perform background authentication
    func performBackgroundAuthentication() {
        guard authenticationService.isUserEnrolled else { return }
        
        // This would be called by the background task service
        let result = authenticationService.performBackgroundAuthentication()
        
        DispatchQueue.main.async {
            switch result {
            case .approved:
                self.isAuthenticated = true
            case .retry, .denied, .error, .pending:
                self.isAuthenticated = false
            }
        }
    }
    
    // MARK: - Data Synchronization
    
    /// Sync all data to Supabase
    func syncAllData() {
        // Supabase service not available in watch app
        // Data synchronization would be handled by the iOS companion app
    }
    
    // MARK: - Error Handling
    
    func clearError() {
        DispatchQueue.main.async {
            self.errorMessage = nil
        }
        authenticationService.clearError()
        healthKitService.clearError()
        // Supabase service not available in watch app
        bluetoothNFCService.clearError()
    }
    
    // MARK: - Service Access
    
    var healthKit: HealthKitService { healthKitService }
    var authentication: AuthenticationService { authenticationService }
    var data: DataManager { dataManager }
    // Supabase service not available in watch app
    var background: BackgroundTaskService { backgroundTaskService }
    var bluetoothNFC: BluetoothNFCService { bluetoothNFCService }
}

// MARK: - Authentication State

enum AuthenticationState {
    case idle
    case enrolling
    case enrolled
    case authenticating
    case authenticated
    case retryRequired
    case error(String)
    
    var isActive: Bool {
        switch self {
        case .enrolling, .authenticating:
            return true
        default:
            return false
        }
    }
    
    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .enrolling: return "Enrolling"
        case .enrolled: return "Enrolled"
        case .authenticating: return "Authenticating"
        case .authenticated: return "Authenticated"
        case .retryRequired: return "Retry Required"
        case .error: return "Error"
        }
    }
}

