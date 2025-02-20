import SwiftUI
import SwiftData
import CoreLocation

struct SpotListView: View {
    enum FilterType {
        case nearby
        case favorites
    }
    
    let filter: FilterType
    @Environment(\.modelContext) private var modelContext
    @Query private var spots: [Spot]
    @EnvironmentObject private var viewModel: DashboardViewModel
    
    init(filter: FilterType) {
        self.filter = filter
        let predicate: Predicate<Spot>? = filter == .favorites ? #Predicate<Spot> { spot in
            spot.isFavorite
        } : nil
        
        self._spots = Query(filter: predicate, sort: \Spot.name)
    }
    
    var sortedSpots: [Spot] {
        if filter == .nearby, let location = viewModel.userLocation {
            return spots.sorted { spot1, spot2 in
                let loc1 = CLLocation(
                    latitude: Double(truncating: spot1.latitude as NSDecimalNumber),
                    longitude: Double(truncating: spot1.longitude as NSDecimalNumber)
                )
                let loc2 = CLLocation(
                    latitude: Double(truncating: spot2.latitude as NSDecimalNumber),
                    longitude: Double(truncating: spot2.longitude as NSDecimalNumber)
                )
                return location.distance(from: loc1) < location.distance(from: loc2)
            }
        }
        return spots
    }
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if spots.isEmpty {
                    emptyStateView
                } else {
                    spotsList
                }
            }
            .navigationTitle(filter == .nearby ? "Nearby Spots" : "Favorites")
            .refreshable {
                await viewModel.refreshSpots()
            }
            .toolbar {
                if filter == .nearby {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            viewModel.requestLocationUpdate()
                        } label: {
                            Image(systemName: "location.circle")
                                .foregroundColor(viewModel.userLocation != nil ? .blue : .gray)
                        }
                    }
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: filter == .nearby ? "location.slash" : "star.slash")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(filter == .nearby ? "No Nearby Spots" : "No Favorite Spots")
                .font(.headline)
            
            if filter == .nearby {
                if viewModel.locationAuthorizationStatus == .denied || 
                   viewModel.locationAuthorizationStatus == .restricted {
                    Text("Location access is restricted. Please enable it in Settings to see nearby spots.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                } else if viewModel.userLocation == nil {
                    Text("Enable location services to find nearby spots")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button {
                        viewModel.requestLocationUpdate()
                    } label: {
                        Text("Enable Location")
                            .bold()
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Text("Pull to refresh nearby spots")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                Text("Add spots to your favorites")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    private var spotsList: some View {
        List {
            ForEach(sortedSpots) { spot in
                NavigationLink(destination: SpotDetailView(spot: spot)) {
                    SpotRowView(spot: spot)
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Spot.self, Alert.self, User.self, configurations: config)
    let context = container.mainContext
    let viewModel = DashboardViewModel()
    
    // Create sample data
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
    viewModel.setModelContext(context)
    
    return SpotListView(filter: .nearby)
        .modelContainer(container)
        .environmentObject(viewModel)
} 