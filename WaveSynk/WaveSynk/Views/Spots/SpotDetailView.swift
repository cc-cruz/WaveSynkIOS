import SwiftUI
import MapKit

struct SpotDetailView: View {
    let spot: Spot
    @StateObject private var viewModel: SpotDetailViewModel
    @State private var selectedTimeRange: TimeRange = .today
    
    enum TimeRange {
        case today
        case tomorrow
        case week
    }
    
    init(spot: Spot) {
        self.spot = spot
        self._viewModel = StateObject(wrappedValue: SpotDetailViewModel(spot: spot))
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: DesignSystem.Layout.spacing) {
                // Map View
                Map(coordinateRegion: .constant(MKCoordinateRegion(
                    center: spot.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )))
                .frame(height: 200)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Layout.cornerRadius))
                
                // Current Conditions
                if let currentCondition = viewModel.currentConditions {
                    currentConditionsView(currentCondition)
                }
                
                // Best Time to Surf
                if let bestTime = viewModel.getBestTimeToSurf() {
                    bestTimeView(bestTime)
                }
                
                // Time Range Picker
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    Text("Today").tag(TimeRange.today)
                    Text("Tomorrow").tag(TimeRange.tomorrow)
                    Text("Week").tag(TimeRange.week)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTimeRange) { _ in
                    Task {
                        await viewModel.refresh()
                    }
                }
                
                // Forecast
                if !viewModel.forecast.isEmpty {
                    forecastView
                } else if viewModel.isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("No forecast available")
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Spot Details
                spotDetailsView
            }
            .padding()
        }
        .navigationTitle(spot.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.toggleFavorite()
                } label: {
                    Image(systemName: spot.isFavorite ? "star.fill" : "star")
                        .foregroundColor(spot.isFavorite ? .yellow : .gray)
                }
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    viewModel.showCreateAlert = true
                } label: {
                    Image(systemName: "bell.badge.plus")
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showCreateAlert) {
            CreateAlertView(spot: spot)
        }
        .alert("Error", isPresented: .init(
            get: { viewModel.error != nil },
            set: { if !$0 { viewModel.error = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = viewModel.error {
                Text(error)
            }
        }
    }
    
    private func currentConditionsView(_ condition: Condition) -> some View {
        VStack(spacing: 16) {
            Text("Current Conditions")
                .font(.headline)
            
            HStack(spacing: 32) {
                VStack {
                    Image(systemName: "water.waves")
                        .font(.title)
                    Text(condition.formattedWaveHeight)
                        .font(.subheadline)
                    Text("Wave Height")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack {
                    Image(systemName: "wind")
                        .font(.title)
                    Text(condition.formattedWindSpeed)
                        .font(.subheadline)
                    Text("Wind Speed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let temp = condition.formattedWaterTemperature {
                    VStack {
                        Image(systemName: "thermometer")
                            .font(.title)
                        Text(temp)
                            .font(.subheadline)
                        Text("Water Temp")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            if condition.isLive {
                Text("Live Buoy Data")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.vertical, 4)
            }
            
            Text("Wave Quality: \(condition.qualityDescription)")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
    
    private func bestTimeView(_ bestTime: Date) -> some View {
        VStack(spacing: 8) {
            Label {
                Text("Best Time to Surf")
                    .font(.headline)
            } icon: {
                Image(systemName: "star.circle.fill")
                    .foregroundColor(.yellow)
            }
            
            Text(formatBestTime(bestTime))
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
    
    private func formatBestTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private var forecastView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Forecast")
                .font(.headline)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.forecast) { forecast in
                        VStack(spacing: 8) {
                            Text(formatTime(forecast.timestamp))
                                .font(.caption)
                            
                            VStack(spacing: 4) {
                                Image(systemName: "water.waves")
                                Text(forecast.formattedWaveHeight)
                                    .font(.subheadline)
                            }
                            
                            VStack(spacing: 4) {
                                Image(systemName: "wind")
                                Text(forecast.formattedWindSpeed)
                                    .font(.subheadline)
                            }
                            
                            if let temp = forecast.formattedWaterTemperature {
                                VStack(spacing: 4) {
                                    Image(systemName: "thermometer")
                                    Text(temp)
                                        .font(.subheadline)
                                }
                            }
                            
                            // Confidence indicator
                            ProgressView(value: Double(forecast.confidence) / 100.0)
                                .tint(confidenceColor(forecast.confidence))
                                .frame(width: 40)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(DesignSystem.Layout.cornerRadius)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func confidenceColor(_ confidence: Int) -> Color {
        switch confidence {
        case 0..<50:
            return .red
        case 50..<70:
            return .orange
        case 70..<90:
            return .yellow
        default:
            return .green
        }
    }
    
    private var spotDetailsView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spot Details")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                detailRow(title: "Region", value: spot.region ?? "Unknown")
                detailRow(title: "Type", value: spot.spotType ?? "Unknown")
                detailRow(title: "Difficulty", value: spot.difficulty ?? "Unknown")
                detailRow(title: "Consistency", value: spot.consistency ?? "Unknown")
                
                if let parkingInfo = spot.metadata["parking_info"] {
                    detailRow(title: "Parking", value: parkingInfo)
                }
                
                if let localTips = spot.metadata["local_tips"] {
                    detailRow(title: "Local Tips", value: localTips)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(DesignSystem.Layout.cornerRadius)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "ha"
        return formatter.string(from: date)
    }
}

// MARK: - View Model
@MainActor
class SpotDetailViewModel: ObservableObject {
    @Published var currentConditions: Condition?
    @Published var forecast: [Forecast] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var showCreateAlert = false
    @Published var selectedTimeRange: TimeRange = .today
    
    private let spot: Spot
    private let networkManager = NetworkManager.shared
    private let forecastService = ForecastService.shared
    
    init(spot: Spot) {
        self.spot = spot
        Task {
            await refresh()
        }
    }
    
    func refresh() async {
        isLoading = true
        error = nil
        
        do {
            // Fetch current conditions
            let conditions = try await networkManager.fetchConditions(for: spot.id)
            self.currentConditions = conditions.first
            
            // Fetch forecast based on selected time range
            let forecasts = try await networkManager.fetchForecast(for: spot.id)
            self.forecast = filterForecasts(forecasts)
        } catch {
            self.error = "Failed to load conditions and forecast"
        }
        
        isLoading = false
    }
    
    private func filterForecasts(_ forecasts: [Forecast]) -> [Forecast] {
        let calendar = Calendar.current
        let now = Date()
        
        switch selectedTimeRange {
        case .today:
            return forecasts.filter { forecast in
                calendar.isDate(forecast.timestamp, inSameDayAs: now)
            }
        case .tomorrow:
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: now)!
            return forecasts.filter { forecast in
                calendar.isDate(forecast.timestamp, inSameDayAs: tomorrow)
            }
        case .week:
            let oneWeek = calendar.date(byAdding: .day, value: 7, to: now)!
            return forecasts.filter { forecast in
                forecast.timestamp <= oneWeek
            }
        }
    }
    
    func toggleFavorite() {
        spot.isFavorite.toggle()
        // Save changes through SwiftData context
        if let modelContext = spot.modelContext {
            try? modelContext.save()
        }
    }
    
    func getBestTimeToSurf() -> Date? {
        return spot.bestTimeToSurf(on: selectedTimeRange == .tomorrow ? 
            Calendar.current.date(byAdding: .day, value: 1, to: Date())! : Date())
    }
}

#Preview {
    NavigationView {
        SpotDetailView(spot: Spot(
            id: 1,
            name: "Test Beach",
            spitcastId: "test-beach",
            latitude: Decimal(42.3601),
            longitude: Decimal(-71.0589)
        ))
    }
} 