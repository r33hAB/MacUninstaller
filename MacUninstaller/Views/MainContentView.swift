import SwiftUI

struct MainContentView: View {
    @State private var selectedSection: AppSection = .apps
    @StateObject private var dashboardViewModel = DashboardViewModel()
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
            Divider().background(AppTheme.borderLight)
            Group {
                switch selectedSection {
                case .apps:
                    DashboardView(viewModel: dashboardViewModel)
                case .storage:
                    StorageOverviewView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView(isPresented: $showOnboarding)
        }
    }
}
