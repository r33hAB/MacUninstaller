import Foundation
import Security

final class HelperToolDelegate: NSObject, NSXPCListenerDelegate, HelperProtocol {
    private let remover = FileRemover()

    func listener(
        _ listener: NSXPCListener,
        shouldAcceptNewConnection newConnection: NSXPCConnection
    ) -> Bool {
        // Verify the connecting process is our main app
        let pid = newConnection.processIdentifier
        var code: SecCode?
        let status = SecCodeCopyGuestWithAttributes(nil, [kSecGuestAttributePid: pid] as CFDictionary, [], &code)

        guard status == errSecSuccess, let code = code else { return false }

        var info: CFDictionary?
        let infoStatus = SecCodeCopySigningInformation(code, SecCSFlags(rawValue: kSecCSSigningInformation), &info)
        guard infoStatus == errSecSuccess, let info = info as? [String: Any],
              let teamID = info[kSecCodeInfoTeamIdentifier as String] as? String,
              teamID == "4QK74D4L3J" else { return false }

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

