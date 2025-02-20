import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel: DashboardViewModel
    @State private var selectedTab = 0
    @State private var navigationPath = NavigationPath()
    
    init() {
        self._viewModel = StateObject(wrappedValue: DashboardViewModel())
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            TabView(selection: $selectedTab) {
                // Nearby Spots
                SpotListView(filter: .nearby)
                    .tabItem {
                        Label("Nearby", systemImage: "location.fill")
                    }
                    .tag(0)
                
                // Favorites
                SpotListView(filter: .favorites)
                    .tabItem {
                        Label("Favorites", systemImage: "star.fill")
                    }
                    .tag(1)
                
                // Alerts
                AlertsView()
                    .tabItem {
                        Label("Alerts", systemImage: "bell.fill")
                    }
                    .tag(2)
                
                // Profile/Settings
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                    .tag(3)
            }
            .navigationDestination(for: NavigationDestination.self) { destination in
                switch destination {
                case .spot(let spotId):
                    if let spot = try? modelContext.fetch(FetchDescriptor<Spot>(
                        predicate: #Predicate<Spot> { $0.id == spotId }
                    )).first {
                        SpotDetailView(spot: spot)
                    }
                case .alert(let alertId):
                    if let alert = try? modelContext.fetch(FetchDescriptor<Alert>(
                        predicate: #Predicate<Alert> { $0.id == alertId }
                    )).first {
                        AlertDetailView(alert: alert)
                    }
                }
            }
        }
        .environmentObject(viewModel)
        .onAppear {
            viewModel.setModelContext(modelContext)
            NotificationService.shared.configure(with: modelContext) { destination in
                handleNotificationNavigation(destination)
            }
        }
        .task {
            await viewModel.refreshSpots()
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
    
    private func handleNotificationNavigation(_ destination: NotificationDestination) {
        switch destination {
        case .alert(let alertId, let spotId):
            selectedTab = 2 // Switch to Alerts tab
            navigationPath.append(NavigationDestination.alert(alertId))
        }
    }
}

// MARK: - Navigation Types
enum NavigationDestination: Hashable {
    case spot(Int)
    case alert(Int)
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Spot.self, Alert.self, User.self, configurations: config)
    
    // Create sample data
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
                    consistency: "Good")
    
    context.insert(spot)
    
    return DashboardView()
        .modelContainer(container)
} 