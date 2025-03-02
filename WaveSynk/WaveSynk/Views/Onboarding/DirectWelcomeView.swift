import SwiftUI

struct DirectWelcomeView: View {
    @State private var isAnimating = false
    @State private var showDashboard = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    DesignSystem.Colors.primary,
                    DesignSystem.Colors.secondary
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and app name
                VStack(spacing: 20) {
                    Image(systemName: "wave.3.right.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    Text("WaveSynk")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                    
                    Text("Catch the perfect wave")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 15)
                }
                
                Spacer()
                
                // Wave illustration
                Image(systemName: "water.waves")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240)
                    .foregroundColor(.white.opacity(0.7))
                    .opacity(isAnimating ? 1 : 0)
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button {
                        // Go to dashboard
                        showDashboard = true
                    } label: {
                        Text("Get Started")
                            .font(.headline)
                            .foregroundColor(DesignSystem.Colors.secondary)
                            .frame(height: 55)
                            .frame(maxWidth: .infinity)
                            .background(Color.white)
                            .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                    
                    Button {
                        // Go to login
                        showDashboard = true
                    } label: {
                        Text("I already have an account")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .underline()
                    }
                    .padding(.bottom, 30)
                    .opacity(isAnimating ? 1 : 0)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
        .fullScreenCover(isPresented: $showDashboard) {
            DashboardView()
        }
    }
}

#Preview {
    DirectWelcomeView()
} 