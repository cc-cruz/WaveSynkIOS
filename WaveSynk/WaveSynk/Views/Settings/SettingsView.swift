import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var currentUser: User?
    
    @State private var notificationsEnabled = true
    @State private var showNotificationSettings = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isUpdatingNotifications = false
    
    private let pushService = PushNotificationService.shared
    
    var body: some View {
        NavigationView {
            List {
                Section("Notifications") {
                    Toggle("Enable Notifications", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            Task {
                                await updateNotificationSettings(enabled: newValue)
                            }
                        }
                        .disabled(isUpdatingNotifications)
                    
                    Button("Notification Settings") {
                        showNotificationSettings = true
                    }
                    
                    if isUpdatingNotifications {
                        HStack {
                            Spacer()
                            ProgressView()
                                .progressViewStyle(.circular)
                            Spacer()
                        }
                    }
                }
                
                Section("Account") {
                    if let user = currentUser {
                        LabeledContent("Username", value: user.username)
                        LabeledContent("Email", value: user.email)
                        if let phone = user.phone {
                            LabeledContent("Phone", value: phone)
                        }
                    }
                }
                
                Section("About") {
                    LabeledContent("Version", value: Configuration.Version.full)
                    if Configuration.Version.isPreRelease {
                        Text("Pre-release build")
                            .font(.caption)
                            .foregroundColor(DesignSystem.Colors.warning)
                    }
                    LabeledContent("Minimum iOS Version", value: Configuration.Version.minimumOSVersion)
                    Link("Privacy Policy", destination: URL(string: "https://wavesynk.com/privacy")!)
                    Link("Terms of Service", destination: URL(string: "https://wavesynk.com/terms")!)
                }
            }
            .navigationTitle("Settings")
            .alert("Error", isPresented: $showError) {
                Button("OK") {
                    showError = false
                }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            notificationsEnabled = currentUser?.notificationsEnabled ?? true
        }
        .onChange(of: currentUser?.notificationsEnabled) { newValue in
            notificationsEnabled = newValue ?? true
        }
        .sheet(isPresented: $showNotificationSettings) {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                SafariView(url: url)
            }
        }
    }
    
    private func updateNotificationSettings(enabled: Bool) async {
        guard let user = currentUser else { return }
        
        isUpdatingNotifications = true
        defer { isUpdatingNotifications = false }
        
        do {
            if enabled {
                // Request notification permissions
                try await pushService.requestAuthorization()
            } else {
                // Clear device token and unregister from backend
                try await pushService.clearDeviceToken()
            }
            
            // Update user preferences locally
            user.notificationsEnabled = enabled
            try modelContext.save()
            
            // Update notification scheduling
            if enabled {
                NotificationService.shared.scheduleBackgroundRefresh()
            } else {
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            
            // Sync with backend
            try await NetworkManager.shared.updatePushPreferences(enabled: enabled)
            
        } catch {
            // Show error and revert changes
            errorMessage = error.localizedDescription
            showError = true
            
            // Revert changes
            user.notificationsEnabled = !enabled
            try? modelContext.save()
            notificationsEnabled = !enabled
        }
    }
}

// MARK: - Safari View
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}

// MARK: - Bundle Extension
extension Bundle {
    var appVersion: String {
        "\(infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0").\(infoDictionary?["CFBundleVersion"] as? String ?? "0")"
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: User.self, configurations: config)
    let context = container.mainContext
    
    let user = User(id: 1,
                    username: "testuser",
                    email: "test@example.com",
                    phone: "+1234567890",
                    notificationsEnabled: true)
    
    context.insert(user)
    
    return SettingsView()
        .modelContainer(container)
} 