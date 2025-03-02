import SwiftUI
import SwiftData

struct CreateAlertView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Spot.name) private var spots: [Spot]
    
    let selectedSpot: Spot?
    
    @State private var minWaveHeight: Double = 2.0
    @State private var maxWaveHeight: Double = 4.0
    @State private var minWindSpeed: Double = 0.0
    @State private var maxWindSpeed: Double = 15.0
    @State private var selectedSpotId: Int?
    @State private var selectedWindDirections: Set<String> = []
    @State private var isLoading = false
    @State private var error: String?
    @State private var showError = false
    
    private let windDirections = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
    
    init(spot: Spot? = nil) {
        self.selectedSpot = spot
        self._selectedSpotId = State(initialValue: spot?.id)
    }
    
    private var isValid: Bool {
        guard selectedSpot != nil || selectedSpotId != nil else { return false }
        guard minWaveHeight <= maxWaveHeight else { return false }
        guard minWindSpeed <= maxWindSpeed else { return false }
        return true
    }
    
    var body: some View {
        NavigationView {
            Form {
                if selectedSpot == nil {
                    Section("Spot") {
                        Picker("Select Spot", selection: $selectedSpotId) {
                            Text("Select a spot")
                                .tag(nil as Int?)
                            
                            ForEach(spots) { spot in
                                Text(spot.name)
                                    .tag(spot.id as Int?)
                            }
                        }
                    }
                }
                
                Section("Wave Height") {
                    VStack {
                        HStack {
                            Text("\(minWaveHeight, specifier: "%.1f") ft")
                            Spacer()
                            Text("\(maxWaveHeight, specifier: "%.1f") ft")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Slider(value: $minWaveHeight,
                                   in: 0...maxWaveHeight,
                                   step: 0.5)
                            Slider(value: $maxWaveHeight,
                                   in: minWaveHeight...15,
                                   step: 0.5)
                        }
                    }
                }
                
                Section("Wind Speed") {
                    VStack {
                        HStack {
                            Text("\(minWindSpeed, specifier: "%.0f") mph")
                            Spacer()
                            Text("\(maxWindSpeed, specifier: "%.0f") mph")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                        
                        HStack {
                            Slider(value: $minWindSpeed,
                                   in: 0...maxWindSpeed,
                                   step: 1)
                            Slider(value: $maxWindSpeed,
                                   in: minWindSpeed...30,
                                   step: 1)
                        }
                    }
                }
                
                Section("Wind Direction") {
                    Text("Select preferred wind directions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 10) {
                        ForEach(windDirections, id: \.self) { direction in
                            Button {
                                toggleWindDirection(direction)
                            } label: {
                                Text(direction)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(selectedWindDirections.contains(direction) ?
                                              Color.blue : Color(.systemGray5))
                                    .foregroundColor(selectedWindDirections.contains(direction) ?
                                                   .white : .primary)
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    Button {
                        createAlert()
                    } label: {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Create Alert")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isValid || isLoading)
                }
            }
            .navigationTitle("Create Alert")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(error ?? "An unknown error occurred")
            }
        }
    }
    
    private func toggleWindDirection(_ direction: String) {
        if selectedWindDirections.contains(direction) {
            selectedWindDirections.remove(direction)
        } else {
            selectedWindDirections.insert(direction)
        }
    }
    
    private func createAlert() {
        guard let spot = selectedSpot ?? spots.first(where: { $0.id == selectedSpotId }) else {
            return
        }
        
        isLoading = true
        error = nil
        
        let alert = Alert(
            id: Int.random(in: 1...Int.max), // In production, this would come from the server
            userId: 1, // This would come from the authenticated user
            spotId: spot.id,
            minWaveHeight: Decimal(minWaveHeight),
            maxWaveHeight: Decimal(maxWaveHeight),
            minWindSpeed: Decimal(minWindSpeed),
            maxWindSpeed: Decimal(maxWindSpeed),
            preferredWindDirections: Array(selectedWindDirections),
            enabled: true
        )
        
        alert.spot = spot
        modelContext.insert(alert)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            self.error = "Failed to create alert"
            self.showError = true
            isLoading = false
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Alert.self, Spot.self, User.self, configurations: config)
    let context = container.mainContext
    
    // Create sample data
    let spot = Spot(
        id: 1,
        name: "Ocean Beach",
        spitcastId: "OB",
        latitude: Decimal(37.7558),
        longitude: Decimal(-122.5130)
    )
    
    context.insert(spot)
    
    return CreateAlertView()
        .modelContainer(container)
} 