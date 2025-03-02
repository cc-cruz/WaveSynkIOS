import SwiftUI
import SwiftData

struct AlertsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: [SortDescriptor(\Alert.enabled, order: .reverse),
                  SortDescriptor(\Alert.id)]) private var alerts: [Alert]
    @State private var showCreateAlert = false
    @State private var alertToDelete: Alert?
    @State private var showInactiveAlerts = false
    
    var filteredAlerts: [Alert] {
        showInactiveAlerts ? alerts : alerts.filter { $0.enabled }
    }
    
    var body: some View {
        NavigationView {
            Group {
                if alerts.isEmpty {
                    emptyStateView
                } else if filteredAlerts.isEmpty {
                    noActiveAlertsView
                } else {
                    alertsList
                }
            }
            .navigationTitle("My Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateAlert = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Toggle(isOn: $showInactiveAlerts) {
                        Text("Show Inactive")
                            .font(.caption)
                    }
                    .toggleStyle(.switch)
                    .labelsHidden()
                }
            }
            .sheet(isPresented: $showCreateAlert) {
                CreateAlertView()
            }
            .confirmationDialog(
                "Are you sure you want to delete this alert?",
                isPresented: .constant(alertToDelete != nil),
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let alert = alertToDelete {
                        Task {
                            await deleteAlert(alert)
                        }
                    }
                    alertToDelete = nil
                }
                
                Button("Cancel", role: .cancel) {
                    alertToDelete = nil
                }
            }
        }
    }
    
    // MARK: - Views
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Alerts Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Create your first alert to get notified when conditions are perfect for surfing.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showCreateAlert = true
            }) {
                Text("Create Alert")
                    .fontWeight(.semibold)
                    .padding()
                    .background(DesignSystem.Colors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var noActiveAlertsView: some View {
        VStack(spacing: 20) {
            Image(systemName: "bell.badge.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Active Alerts")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("You have alerts, but none are currently active. Toggle the switch to view inactive alerts.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            Button(action: {
                showInactiveAlerts = true
            }) {
                Text("Show Inactive Alerts")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private var alertsList: some View {
        List {
            ForEach(filteredAlerts, id: \.id) { alert in
                NavigationLink(destination: AlertDetailView(alert: alert)) {
                    AlertRowView(alert: alert)
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        alertToDelete = alert
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        toggleAlertEnabled(alert)
                    } label: {
                        Label(
                            alert.enabled ? "Disable" : "Enable",
                            systemImage: alert.enabled ? "bell.slash" : "bell.fill"
                        )
                    }
                    .tint(alert.enabled ? .gray : .green)
                }
            }
        }
    }
    
    // MARK: - Alert Status Indicator
    
    private func alertStatusIndicator(for alert: Alert) -> some View {
        HStack {
            Image(systemName: "bell.fill")
                .foregroundColor(alert.enabled ? .green : .gray)
            Text(alert.enabled ? "Active" : "Paused")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func conditionRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
            Text(value)
        }
    }
}

@MainActor
class AlertsViewModel: ObservableObject {
    @Published var alerts: [Alert] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let networkManager = NetworkManager.shared
    
    func fetchAlerts() async {
        isLoading = true
        error = nil
        
        do {
            // Assuming we have a way to get the current user ID
            let userId = UserDefaults.standard.integer(forKey: "currentUserId")
            alerts = try await networkManager.fetchAlerts(for: userId)
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func deleteAlert(_ alert: Alert) async {
        isLoading = true
        error = nil
        
        do {
            try await networkManager.deleteAlert(alert.id)
            // SwiftData will handle removing the alert from the alerts array
        } catch {
            self.error = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func toggleAlertEnabled(_ alert: Alert) {
        // Toggle the enabled state
        alert.enabled.toggle()
        
        // Update on the server
        Task {
            do {
                try await networkManager.updateAlert(alert)
            } catch {
                // Revert the change if the server update fails
                alert.enabled.toggle()
                self.error = error.localizedDescription
            }
        }
    }
}

// MARK: - View Extension

extension AlertsView {
    private func toggleAlertEnabled(_ alert: Alert) {
        // Toggle the enabled state locally
        alert.enabled.toggle()
        
        // Try to save the change
        do {
            try modelContext.save()
            
            // Update on the server
            Task {
                do {
                    try await NetworkManager.shared.updateAlert(alert)
                } catch {
                    // Revert the change if the server update fails
                    alert.enabled.toggle()
                    try? modelContext.save()
                }
            }
        } catch {
            // Revert if local save fails
            alert.enabled.toggle()
        }
    }
    
    private func deleteAlert(_ alert: Alert) async {
        isLoading = false
        
        do {
            try await networkManager.deleteAlert(alert.id)
            // SwiftData will handle removing the alert from the alerts array
        } catch {
            self.error = error.localizedDescription
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        AlertsView()
    }
    .modelContainer(for: Alert.self, inMemory: true, isStoredInMemoryOnly: true) { container in
        let spot = Spot(id: 1,
                       name: "Mavericks",
                       latitude: 37.4936,
                       longitude: -122.5010,
                       region: "Northern California",
                       country: "USA")
        
        container.mainContext.insert(spot)
        
        let alert1 = Alert(id: 1,
                          userId: 1,
                          spotId: 1,
                          minWaveHeight: Decimal(3),
                          maxWaveHeight: Decimal(5),
                          minWindSpeed: Decimal(5),
                          maxWindSpeed: Decimal(15),
                          preferredWindDirections: ["N", "NW"],
                          enabled: true)
        
        let alert2 = Alert(id: 2,
                          userId: 1,
                          spotId: 1,
                          minWaveHeight: Decimal(4),
                          maxWaveHeight: Decimal(6),
                          minWindSpeed: Decimal(3),
                          maxWindSpeed: Decimal(10),
                          preferredWindDirections: ["S", "SE"],
                          enabled: false)
        
        container.mainContext.insert(alert1)
        container.mainContext.insert(alert2)
    }
} 