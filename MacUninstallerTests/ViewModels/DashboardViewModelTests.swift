import XCTest
@testable import MacUninstaller

@MainActor
final class DashboardViewModelTests: XCTestCase {

    private func makeSampleApps() -> [AppInfo] {
        [
            AppInfo(name: "Alpha", bundleIdentifier: "com.test.alpha",
                    bundlePath: URL(filePath: "/Applications/Alpha.app"),
                    icon: nil, bundleSize: 300_000_000, source: .manual,
                    installDate: nil, lastUsedDate: Date()),
            AppInfo(name: "Beta", bundleIdentifier: "com.test.beta",
                    bundlePath: URL(filePath: "/Applications/Beta.app"),
                    icon: nil, bundleSize: 100_000_000, source: .appStore,
                    installDate: nil,
                    lastUsedDate: Calendar.current.date(byAdding: .day, value: -120, to: Date())),
            AppInfo(name: "Gamma", bundleIdentifier: "com.test.gamma",
                    bundlePath: URL(filePath: "/Applications/Gamma.app"),
                    icon: nil, bundleSize: 500_000_000, source: .manual,
                    installDate: nil, lastUsedDate: Date()),
        ]
    }

    func test_filterAll_showsAllApps() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.activeFilter = .all
        XCTAssertEqual(vm.filteredApps.count, 3)
    }

    func test_filterUnused_showsOnlyUnusedApps() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.activeFilter = .unused
        XCTAssertEqual(vm.filteredApps.count, 1)
        XCTAssertEqual(vm.filteredApps.first?.name, "Beta")
    }

    func test_filterAppStore_showsOnlyAppStoreApps() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.activeFilter = .appStore
        XCTAssertEqual(vm.filteredApps.count, 1)
        XCTAssertEqual(vm.filteredApps.first?.name, "Beta")
    }

    func test_sortBySize_descendingOrder() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.sortOption = .size
        let names = vm.filteredApps.map(\.name)
        XCTAssertEqual(names, ["Gamma", "Alpha", "Beta"])
    }

    func test_sortByName_alphabeticalOrder() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.sortOption = .name
        let names = vm.filteredApps.map(\.name)
        XCTAssertEqual(names, ["Alpha", "Beta", "Gamma"])
    }

    func test_searchFiltersAppsByName() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.searchText = "alph"
        XCTAssertEqual(vm.filteredApps.count, 1)
        XCTAssertEqual(vm.filteredApps.first?.name, "Alpha")
    }

    func test_searchFiltersByBundleID() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.searchText = "com.test.gamma"
        XCTAssertEqual(vm.filteredApps.count, 1)
        XCTAssertEqual(vm.filteredApps.first?.name, "Gamma")
    }

    func test_selectedAppsCount() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.selectedAppIDs.insert(vm.allApps[0].id)
        vm.selectedAppIDs.insert(vm.allApps[2].id)
        XCTAssertEqual(vm.selectedAppsCount, 2)
    }

    func test_selectAll_selectsFilteredApps() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.selectAll()
        XCTAssertEqual(vm.selectedAppIDs.count, 3)
    }

    func test_deselectAll_clearsSelection() {
        let vm = DashboardViewModel()
        vm.allApps = makeSampleApps()
        vm.selectAll()
        vm.deselectAll()
        XCTAssertTrue(vm.selectedAppIDs.isEmpty)
    }
}
