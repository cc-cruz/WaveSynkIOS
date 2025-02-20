import SwiftUI
import SwiftData

struct AlertDetailView: View {
    let alert: Alert
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        List {
            Section {
                // Spot Info
                if let spot = alert.spot {
                    NavigationLink(value: NavigationDestination.spot(spot.id)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(spot.name)
                                .font(.headline)
                            Text(spot.formattedLocation)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            } header: {
                Text("Location")
            }
            
            Section {
                // Wave Height
                LabeledContent("Wave Height") {
                    Text(alert.formattedWaveHeightRange)
                }
                
                // Wind Speed
                LabeledContent("Wind Speed") {
                    Text(alert.formattedWindSpeedRange)
                }
                
                // Wind Directions
                if !alert.preferredWindDirections.isEmpty {
                    LabeledContent("Wind Directions") {
                        Text(alert.formattedWindDirections)
                    }
                }
            } header: {
                Text("Conditions")
            }
            
            Section {
                // Alert Status
                Toggle("Enabled", isOn: Binding(
                    get: { alert.enabled },
                    set: { newValue in
                        alert.enabled = newValue
                        try? modelContext.save()
                    }
                ))
                
                // Last Triggered
                if let lastTriggered = alert.lastTriggered {
                    LabeledContent("Last Triggered") {
                        Text(lastTriggered.formatted())
                    }
                }
                
                // Notifications Sent
                LabeledContent("Notifications Sent") {
                    Text("\(alert.notificationsSent)")
                }
            } header: {
                Text("Status")
            }
            
            Section {
                Button(role: .destructive) {
                    deleteAlert()
                } label: {
                    HStack {
                        Spacer()
                        Text("Delete Alert")
                        Spacer()
                    }
                }
            }
        }
        .navigationTitle("Alert Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func deleteAlert() {
        // Remove relationships before deleting
        alert.spot?.alerts?.removeAll(where: { $0.id == alert.id })
        alert.user?.alerts?.removeAll(where: { $0.id == alert.id })
        
        modelContext.delete(alert)
        try? modelContext.save()
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Alert.self, Spot.self, User.self, configurations: config)
    let context = container.mainContext
    
    let spot = Spot(id: 1,
                    name: "Ocean Beach",
                    spitcastId: "OB",
                    latitude: Decimal(37.7558),
                    longitude: Decimal(-122.5130))
    
    let alert = Alert(id: 1,
                     userId: 1,
                     spotId: 1,
                     minWaveHeight: Decimal(3),
                     maxWaveHeight: Decimal(6),
                     minWindSpeed: Decimal(0),
                     maxWindSpeed: Decimal(15),
                     preferredWindDirections: ["N", "NW"],
                     enabled: true,
                     lastTriggered: Date().addingTimeInterval(-3600),
                     notificationsSent: 5)
    
    alert.spot = spot
    
    context.insert(spot)
    context.insert(alert)
    
    return NavigationStack {
        AlertDetailView(alert: alert)
    }
    .modelContainer(container)
} 