import Foundation

final class HelperToolDelegate: NSObject, NSXPCListenerDelegate, HelperProtocol {
    private let remover = FileRemover()

    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        newConnection.exportedInterface = NSXPCInterface(with: HelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()
        return true
    }

    func removeFiles(
        atPaths paths: [String],
        useTrash: Bool,
        withReply reply: @escaping (Bool, String?) -> Void
    ) {
        let result = remover.remove(paths: paths, useTrash: useTrash)
        reply(result.success, result.error)
    }

    func isAlive(withReply reply: @escaping (Bool) -> Void) {
        reply(true)
    }
}

