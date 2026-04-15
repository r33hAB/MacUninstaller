import Foundation

@objc protocol HelperProtocol {
    func removeFiles(
        atPaths paths: [String],
        useTrash: Bool,
        withReply reply: @escaping (Bool, String?) -> Void
    )

    func isAlive(withReply reply: @escaping (Bool) -> Void)
}
