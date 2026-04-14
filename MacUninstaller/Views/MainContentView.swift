import SwiftUI

struct MainContentView: View {
    @State private var selectedSection: AppSection = .apps

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
            Divider().background(AppTheme.borderLight)
            Group {
                switch selectedSection {
                case .apps:
                    DashboardView()
                case .storage:
                    StorageOverviewView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
