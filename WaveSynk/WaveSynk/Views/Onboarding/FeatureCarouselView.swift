import SwiftUI

struct FeatureCarouselView: View {
    @EnvironmentObject private var controller: OnboardingController
    @State private var currentPage = 0
    
    private let features = [
        OnboardingFeature(
            title: "Real-Time Forecasts",
            description: "Get accurate surf forecasts with wave height, wind conditions, and water temperature.",
            imageName: "chart.xyaxis.line"
        ),
        OnboardingFeature(
            title: "Custom Alerts",
            description: "Set up personalized alerts for your perfect surf conditions.",
            imageName: "bell.badge.waveform"
        ),
        OnboardingFeature(
            title: "Favorite Spots",
            description: "Save your favorite surf spots for quick access and monitoring.",
            imageName: "star.fill"
        ),
        OnboardingFeature(
            title: "Detailed Analytics",
            description: "View comprehensive data to make informed decisions about when to surf.",
            imageName: "waveform.path.ecg"
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "0891B2").opacity(0.8),
                    Color(hex: "164E63")
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack {
                // Skip button
                HStack {
                    Spacer()
                    Button {
                        controller.goToNextPage()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Capsule())
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<features.count, id: \.self) { index in
                        FeatureView(feature: features[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
                .indexViewStyle(PageIndexViewStyle(backgroundDisplayMode: .always))
                
                // Navigation buttons
                HStack {
                    // Back button (hidden on first page)
                    Button {
                        withAnimation {
                            currentPage = max(0, currentPage - 1)
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .opacity(currentPage > 0 ? 1 : 0)
                    
                    Spacer()
                    
                    // Next/Continue button
                    Button {
                        if currentPage < features.count - 1 {
                            withAnimation {
                                currentPage += 1
                            }
                        } else {
                            controller.goToNextPage()
                        }
                    } label: {
                        Text(currentPage < features.count - 1 ? "Next" : "Continue")
                            .font(.headline)
                            .foregroundColor(Color(hex: "164E63"))
                            .frame(width: 120, height: 50)
                            .background(Color.white)
                            .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 30)
            }
        }
    }
}

struct FeatureView: View {
    let feature: OnboardingFeature
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Feature icon
            Image(systemName: feature.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.white)
                .padding()
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 160, height: 160)
                )
            
            // Feature title and description
            VStack(spacing: 16) {
                Text(feature.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(feature.description)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            
            Spacer()
            Spacer()
        }
    }
}

struct OnboardingFeature {
    let title: String
    let description: String
    let imageName: String
}

#Preview {
    FeatureCarouselView()
        .environmentObject(OnboardingController())
} 