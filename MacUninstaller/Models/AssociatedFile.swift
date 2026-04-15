import Foundation

struct AssociatedFile: Identifiable, Hashable {
    let id = UUID()
    let path: URL
    let size: Int64
    let category: FileCategory
    let requiresAdmin: Bool
    var isSelected: Bool = true
}
