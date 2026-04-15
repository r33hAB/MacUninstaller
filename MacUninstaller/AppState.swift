import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var pendingUninstallPath: String?
}
