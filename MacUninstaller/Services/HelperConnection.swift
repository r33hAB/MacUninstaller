import Foundation
import ServiceManagement

final class HelperConnection {
    private var connection: NSXPCConnection?

    func connect() -> HelperProtocol? {
        if connection == nil {
            connection = NSXPCConnection(
                machServiceName: AppConstants.helperBundleID,
                options: .privileged
            )
            connection?.remoteObjectInterface = NSXPCInterface(with: HelperProtocol.self)
            connection?.resume()
        }

        return connection?.remoteObjectProxyWithErrorHandler { error in
            print("XPC error: \(error)")
        } as? HelperProtocol
    }

    func removeFiles(paths: [String], useTrash: Bool) async throws -> Bool {
        guard let helper = connect() else {
            throw NSError(domain: "HelperConnection", code: 1,
                         userInfo: [NSLocalizedDescriptionKey: "Cannot connect to helper"])
        }

        return try await withCheckedThrowingContinuation { continuation in
            helper.removeFiles(atPaths: paths, useTrash: useTrash) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: NSError(
                        domain: "HelperTool",
                        code: 2,
                        userInfo: [NSLocalizedDescriptionKey: error ?? "Unknown error"]
                    ))
                }
            }
        }
    }

    func disconnect() {
        connection?.invalidate()
        connection = nil
    }
}
