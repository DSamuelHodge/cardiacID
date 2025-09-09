import SwiftUI
import Combine

struct ProfileView: View {
    // Environment objects
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    // State properties
    @State private var showingEditProfile = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfService = false
    @State private var showingSignOutConfirmation = false
    @State private var isLoading = false
    
    // Private properties
    private let colors = HeartIDColors()
    private var cancellables = Set<AnyCancellable>()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Profile Header
                VStack(spacing: 16) {
                    if let user = authViewModel.currentUser {
                        // User avatar
                        if let profileUrl = user.profileImageUrl, !profileUrl.isEmpty {
                            AsyncImage(url: URL(string: profileUrl)) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } placeholder: {
                                ProgressView()
                                    .frame(width: 100, height: 100)
                            }
                        } else {
                            ZStack {
                                Circle()
                                    .fill(colors.surface)
                                    .frame(width: 100, height: 100)
                                
                                Text(initials(from: user.fullName))
                                    .font(.system(size: 36, weight: .bold))
                                    .foregroundColor(colors.accent)
                            }
                        }
                        
                        // User info
                        VStack(spacing: 4) {
                            Text(user.fullName)
                                .font(.title2)
                                .foregroundColor(colors.text)
                            
                            Text(user.email)
                                .font(.subheadline)
                                .foregroundColor(colors.text.opacity(0.7))
                            
                            Text("Premium Account")
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 4)
                                .background(colors.accent.opacity(0.2))
                                .foregroundColor(colors.accent)
                                .cornerRadius(12)
                                .padding(.top, 4)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 100, height: 100)
                            .foregroundColor(colors.accent)
                        
                        Text("Guest User")
                            .font(.title2)
                    }
                    
                    // Edit profile button
                    Button(action: { showingEditProfile = true }) {
                        HStack {
                            Image(systemName: "pencil")
                                .font(.system(size: 14))
                            Text("Edit Profile")
                                .font(.subheadline)
                        }
                        .foregroundColor(colors.text)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(colors.surface)
                        .cornerRadius(20)
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Device & Security
                VStack(alignment: .leading, spacing: 16) {
                    Text("Device & Security")
                        .font(.headline)
                    
                    NavigationLink(destination: DeviceManagementView()) {
                        SettingsRow(icon: "applewatch", title: "Connected Devices")
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    NavigationLink(destination: SecuritySettingsView()) {
                        SettingsRow(icon: "lock.shield", title: "Security Settings")
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Account Settings
                VStack(alignment: .leading, spacing: 16) {
                    Text("Account Settings")
                        .font(.headline)
                    
                    NavigationLink(destination: NotificationsView()) {
                        SettingsRow(icon: "bell", title: "Notifications")
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    Button(action: { showingPrivacyPolicy = true }) {
                        SettingsRow(icon: "hand.raised", title: "Privacy Policy")
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    NavigationLink(destination: SettingsView()) {
                        SettingsRow(icon: "gear", title: "Settings")
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Subscription
                VStack(alignment: .leading, spacing: 16) {
                    Text("Subscription")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Premium Plan")
                                .font(.subheadline)
                            Text("Active until May 2026")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("Manage")
                                .font(.subheadline)
                                .foregroundColor(colors.accent)
                        }
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Support & Legal
                VStack(alignment: .leading, spacing: 16) {
                    Text("Support & Legal")
                        .font(.headline)
                    
                    Button(action: openHelpCenter) {
                        SettingsRow(icon: "questionmark.circle", title: "Help Center")
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    Button(action: contactSupport) {
                        SettingsRow(icon: "envelope", title: "Contact Support")
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    Button(action: { showingTermsOfService = true }) {
                        SettingsRow(icon: "doc.text", title: "Terms of Service")
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Sign Out Button
                Button(action: { showingSignOutConfirmation = true }) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.text))
                    } else {
                        Text("Sign Out")
                            .foregroundColor(colors.error)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                .disabled(isLoading)
            }
            .padding(.vertical)
        }
        .background(colors.background)
        .navigationTitle("Profile")
        .sheet(isPresented: $showingEditProfile) {
            EditProfileView(user: authViewModel.currentUser)
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            NavigationView {
                PrivacyPolicyView()
            }
        }
        .sheet(isPresented: $showingTermsOfService) {
            NavigationView {
                TermsOfServiceView()
            }
        }
        .alert(isPresented: $showingSignOutConfirmation) {
            Alert(
                title: Text("Sign Out"),
                message: Text("Are you sure you want to sign out? You will need to sign in again to use HeartID."),
                primaryButton: .destructive(Text("Sign Out")) {
                    signOut()
                },
                secondaryButton: .cancel()
            )
        }
    }
    
    // MARK: - Helper Functions
    
    private func initials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = components.first?.first {
            return String(first)
        }
        return "?"
    }
    
    private func signOut() {
        isLoading = true
        authViewModel.signOut()
    }
    
    private func openHelpCenter() {
        // In a real app, would open help center URL
        guard let url = URL(string: "https://heartid.com/help") else { return }
        UIApplication.shared.open(url)
    }
    
    private func contactSupport() {
        // In a real app, would open mail composer
        guard let url = URL(string: "mailto:support@heartid.com") else { return }
        UIApplication.shared.open(url)
    }
}

// MARK: - Settings Row
struct SettingsRow: View {
    let icon: String
    let title: String
    private let colors = HeartIDColors()
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(colors.accent)
                .frame(width: 24)
            Text(title)
                .foregroundColor(colors.text)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(colors.text.opacity(0.6))
                .font(.system(size: 14))
        }
    }
}

// MARK: - Edit Profile View
struct EditProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authViewModel: AuthViewModel
    
    let user: User?
    
    @State private var fullName: String = ""
    @State private var profileImage: UIImage? = nil
    @State private var isShowingImagePicker = false
    @State private var isSaving = false
    
    private let colors = HeartIDColors()
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Picture
                    Button(action: { isShowingImagePicker = true }) {
                        ZStack {
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 120, height: 120)
                                    .clipShape(Circle())
                            } else if let user = user, let profileUrl = user.profileImageUrl, !profileUrl.isEmpty {
                                AsyncImage(url: URL(string: profileUrl)) { image in
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } placeholder: {
                                    ZStack {
                                        Circle()
                                            .fill(colors.surface)
                                            .frame(width: 120, height: 120)
                                        
                                        ProgressView()
                                    }
                                }
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(colors.surface)
                                        .frame(width: 120, height: 120)
                                    
                                    Text(user != nil ? initials(from: user!.fullName) : "?")
                                        .font(.system(size: 40, weight: .bold))
                                        .foregroundColor(colors.accent)
                                }
                            }
                            
                            // Camera icon overlay
                            Circle()
                                .fill(colors.accent)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .foregroundColor(.white)
                                        .font(.system(size: 18))
                                )
                                .offset(x: 40, y: 40)
                        }
                    }
                    .padding(.top, 20)
                    
                    // Form Fields
                    VStack(spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Full Name")
                                .font(.subheadline)
                                .foregroundColor(colors.text.opacity(0.8))
                            
                            TextField("", text: $fullName)
                                .padding()
                                .background(colors.surface)
                                .cornerRadius(12)
                                .foregroundColor(colors.text)
                        }
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
                .padding()
            }
            .background(colors.background)
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") { dismiss() },
                trailing: Button(action: saveProfile) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: colors.text))
                    } else {
                        Text("Save")
                            .bold()
                    }
                }
                .disabled(isSaving || fullName.isEmpty)
            )
            .onAppear {
                if let user = user {
                    fullName = user.fullName
                }
            }
        }
    }
    
    private func initials(from name: String) -> String {
        let components = name.components(separatedBy: " ")
        if components.count > 1, let first = components.first?.first, let last = components.last?.first {
            return String(first) + String(last)
        } else if let first = components.first?.first {
            return String(first)
        }
        return "?"
    }
    
    private func saveProfile() {
        isSaving = true
        
        // In a real app, would save to backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isSaving = false
            dismiss()
        }
    }
}

// MARK: - Notifications View
struct NotificationsView: View {
    @State private var isLoading = false
    @State private var pushNotifications = true
    @State private var emailNotifications = true
    @State private var securityAlerts = true
    @State private var marketingEmails = false
    
    private let colors = HeartIDColors()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // App Notifications
                VStack(alignment: .leading, spacing: 16) {
                    Text("App Notifications")
                        .font(.headline)
                    
                    Toggle(isOn: $pushNotifications) {
                        VStack(alignment: .leading) {
                            Text("Push Notifications")
                                .font(.subheadline)
                            Text("Receive alerts on your device")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    Toggle(isOn: $securityAlerts) {
                        VStack(alignment: .leading) {
                            Text("Security Alerts")
                                .font(.subheadline)
                            Text("Get notified about authentication events")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Email Notifications
                VStack(alignment: .leading, spacing: 16) {
                    Text("Email Notifications")
                        .font(.headline)
                    
                    Toggle(isOn: $emailNotifications) {
                        VStack(alignment: .leading) {
                            Text("Email Notifications")
                                .font(.subheadline)
                            Text("Receive important updates via email")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                    }
                    
                    Divider().background(colors.text.opacity(0.1))
                    
                    Toggle(isOn: $marketingEmails) {
                        VStack(alignment: .leading) {
                            Text("Marketing Emails")
                                .font(.subheadline)
                            Text("Receive product updates and offers")
                                .font(.caption)
                                .foregroundColor(colors.text.opacity(0.6))
                        }
                    }
                }
                .padding()
                .background(colors.surface)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(colors.background)
        .navigationTitle("Notifications")
    }
}

#Preview {
    NavigationView {
        ProfileView()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
