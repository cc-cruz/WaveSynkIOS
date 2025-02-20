import SwiftUI
import SwiftData
import CoreLocation

struct SpotRowView: View {
    let spot: Spot
    @EnvironmentObject private var viewModel: DashboardViewModel
    @Environment(\.modelContext) private var modelContext
    
    private var distance: String? {
        guard let userLocation = viewModel.userLocation else { return nil }
        let spotLocation = CLLocation(
            latitude: Double(truncating: spot.latitude as NSDecimalNumber),
            longitude: Double(truncating: spot.longitude as NSDecimalNumber)
        )
        let distance = userLocation.distance(from: spotLocation)
        
        // Format distance
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Spot Name and Favorite Button
            HStack {
                Text(spot.name)
                    .font(.headline)
                
                if let distance = distance {
                    Text(distance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button {
                    viewModel.toggleFavorite(spot)
                } label: {
                    Image(systemName: spot.isFavorite ? "star.fill" : "star")
                        .foregroundColor(spot.isFavorite ? .yellow : .gray)
                }
            }
            
            // Current Conditions (if available)
            if let currentCondition = spot.conditions?.first {
                HStack(spacing: 16) {
                    // Wave Height
                    Label(
                        currentCondition.formattedWaveHeight,
                        systemImage: "water.waves"
                    )
                    
                    // Wind Speed
                    Label(
                        currentCondition.formattedWindSpeed,
                        systemImage: "wind"
                    )
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
            
            // Location
            Text(spot.region ?? "Unknown Location")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Spot.self, Alert.self, User.self, configurations: config)
    let context = container.mainContext
    
    let spot = Spot(id: 1,
                    name: "Ocean Beach",
                    spitcastId: "OB",
                    latitude: Decimal(37.7558),
                    longitude: Decimal(-122.5130),
                    region: "San Francisco",
                    subRegion: "Northern California",
                    spotType: "Beach Break",
                    difficulty: "Advanced",
                    consistency: "Good",
                    metadata: [:],
                    isFavorite: true)
    
    let condition = Condition(id: 1,
                            spotId: 1,
                            timestamp: Date(),
                            waveHeight: Decimal(4.5),
                            wavePeriod: Decimal(12),
                            windSpeed: Decimal(10),
                            windDirection: "NW")
    
    spot.conditions = [condition]
    condition.spot = spot
    
    let viewModel = DashboardViewModel(modelContext: context)
    
    return SpotRowView(spot: spot)
        .modelContainer(container)
        .environmentObject(viewModel)
        .padding()
} 