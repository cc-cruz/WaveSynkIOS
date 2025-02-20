import SwiftUI
import SwiftData

struct AlertRowView: View {
    let alert: Alert
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Spot Name and Toggle
            HStack {
                Text(alert.spot?.name ?? "Unknown Spot")
                    .font(.headline)
                
                Spacer()
                
                Toggle("Enable Alert", isOn: Binding(
                    get: { alert.enabled },
                    set: { newValue in
                        alert.enabled = newValue
                        try? modelContext.save()
                    }
                ))
                .labelsHidden()
            }
            
            // Wave Height Range
            Label {
                Text("\(formatHeight(alert.minWaveHeight)) - \(formatHeight(alert.maxWaveHeight))")
            } icon: {
                Image(systemName: "water.waves")
            }
            .foregroundColor(.secondary)
            
            // Max Wind Speed
            Label {
                Text("Up to \(formatSpeed(alert.maxWindSpeed))")
            } icon: {
                Image(systemName: "wind")
            }
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatHeight(_ height: Decimal) -> String {
        String(format: "%.1f ft", Double(truncating: height as NSDecimalNumber))
    }
    
    private func formatSpeed(_ speed: Decimal) -> String {
        String(format: "%.1f mph", Double(truncating: speed as NSDecimalNumber))
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
                     maxWindSpeed: Decimal(15),
                     enabled: true)
    
    alert.spot = spot
    
    return AlertRowView(alert: alert)
        .modelContainer(container)
        .padding()
} 