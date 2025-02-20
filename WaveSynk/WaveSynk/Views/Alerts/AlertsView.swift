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
            .navigationTitle("Surf Alerts")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCreateAlert = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                
                if !alerts.isEmpty {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            showInactiveAlerts.toggle()
                        } label: {
                            Image(systemName: showInactiveAlerts ? "bell.fill" : "bell.slash.fill")
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateAlert) {
                CreateAlertView()
            }
            .alert("Delete Alert", isPresented: .constant(alertToDelete != nil)) {
                Button("Cancel", role: .cancel) {
                    alertToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    deleteAlert()
                }
            } message: {
                if let alert = alertToDelete {
                    Text("Are you sure you want to delete the alert for \(alert.spot?.name ?? "Unknown Spot")?")
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Alerts")
                .font(.headline)
            
            Text("Create an alert to get notified when conditions are right")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showCreateAlert = true
            } label: {
                Text("Create Alert")
                    .bold()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var noActiveAlertsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "bell.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Active Alerts")
                .font(.headline)
            
            Text("All your alerts are currently disabled")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                showInactiveAlerts = true
            } label: {
                Text("Show Inactive Alerts")
                    .bold()
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var alertsList: some View {
        List {
            ForEach(filteredAlerts) { alert in
                AlertRowView(alert: alert)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            alertToDelete = alert
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .swipeActions(edge: .leading) {
                        Button {
                            toggleAlert(alert)
                        } label: {
                            Label(alert.enabled ? "Disable" : "Enable",
                                  systemImage: alert.enabled ? "bell.slash.fill" : "bell.fill")
                        }
                        .tint(alert.enabled ? .orange : .green)
                    }
            }
        }
    }
    
    private func deleteAlert() {
        guard let alert = alertToDelete else { return }
        
        // Remove relationships before deleting
        alert.spot?.alerts?.removeAll(where: { $0.id == alert.id })
        alert.user?.alerts?.removeAll(where: { $0.id == alert.id })
        
        modelContext.delete(alert)
        try? modelContext.save()
        alertToDelete = nil
    }
    
    private func toggleAlert(_ alert: Alert) {
        alert.enabled.toggle()
        try? modelContext.save()
    }
}

struct AlertRow: View {
    let alert: SurfAlert
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(alert.spot.name)
                    .font(.headline)
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        onDelete()
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.secondary)
                }
            }
            
            Group {
                conditionRow(title: "Wave Height", value: alert.waveHeightRange)
                conditionRow(title: "Wind Speed", value: alert.windSpeedRange)
                if let swellPeriod = alert.swellPeriodRange {
                    conditionRow(title: "Swell Period", value: swellPeriod)
                }
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: "bell.fill")
                    .foregroundColor(alert.isEnabled ? .green : .gray)
                Text(alert.isEnabled ? "Active" : "Paused")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
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
    @Published var alerts: [SurfAlert] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showError = false
    
    private let networkManager = NetworkManager.shared
    
    init() {
        Task {
            await refresh()
        }
    }
    
    func refresh() async {
        isLoading = true
        error = nil
        
        do {
            alerts = try await networkManager.fetchAlerts()
        } catch {
            self.error = "Failed to load alerts"
            self.showError = true
        }
        
        isLoading = false
    }
    
    func deleteAlert(_ alert: SurfAlert) async {
        do {
            try await networkManager.deleteAlert(alert.id)
            if let index = alerts.firstIndex(where: { $0.id == alert.id }) {
                alerts.remove(at: index)
            }
        } catch {
            self.error = "Failed to delete alert"
            self.showError = true
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Alert.self, Spot.self, User.self, configurations: config)
    let context = container.mainContext
    
    // Create sample data
    let user = User(id: 1, username: "testuser", phone: "+1234567890")
    let spot = Spot(id: 1,
                   name: "Ocean Beach",
                   spitcastId: "OB",
                   latitude: Decimal(37.7558),
                   longitude: Decimal(-122.5130))
    
    let alert1 = Alert(id: 1,
                     userId: 1,
                     spotId: 1,
                     minWaveHeight: Decimal(3),
                     maxWaveHeight: Decimal(6),
                     maxWindSpeed: Decimal(15),
                     enabled: true)
    
    let alert2 = Alert(id: 2,
                     userId: 1,
                     spotId: 1,
                     minWaveHeight: Decimal(2),
                     maxWaveHeight: Decimal(4),
                     maxWindSpeed: Decimal(10),
                     enabled: false)
    
    alert1.user = user
    alert1.spot = spot
    alert2.user = user
    alert2.spot = spot
    user.alerts = [alert1, alert2]
    spot.alerts = [alert1, alert2]
    
    context.insert(user)
    context.insert(spot)
    context.insert(alert1)
    context.insert(alert2)
    
    return AlertsView()
        .modelContainer(container)
} 