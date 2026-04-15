import Foundation
import AppKit
import LocalAuthentication
import Security

enum UninstallError: Error, LocalizedError {
    case permissionDenied(path: String)
    case partialFailure(removed: [URL], failed: [(URL, Error)])
    case cancelled
    case authFailed(String)

    var errorDescription: String? {
        switch self {
        case .permissionDenied(let path): return "Permission denied: \(path)"
        case .partialFailure(let removed, let failed): return "Removed \(removed.count) items, \(failed.count) failed"
        case .cancelled: return "Uninstall cancelled"
        case .authFailed(let msg): return "Authorization failed: \(msg)"
        }
    }
}

struct UninstallResult {
    let removedPaths: [URL]
    let failedPaths: [(path: URL, error: Error)]
    let totalFreedBytes: Int64
    var isComplete: Bool { failedPaths.isEmpty }
}

final class UninstallService {
    private let fileManager = FileManager.default
    private static let keychainService = "com.r33hab.macuninstall.admin"
    private static let keychainAccount = "admin-password"
    private static var cachedPassword: String?

    // MARK: - Keychain (plain, no biometry flags)

    private func saveToKeychain(password: String) {
        let delete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(delete as CFDictionary)

        let add: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: password.data(using: .utf8)!
        ]
        let status = SecItemAdd(add as CFDictionary, nil)
        print("Keychain save: \(status == errSecSuccess ? "OK" : "FAILED (\(status))")")
    }

    private func loadFromKeychain() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess, let data = result as? Data {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }

    private func clearKeychain() {
        let delete: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount
        ]
        SecItemDelete(delete as CFDictionary)
        Self.cachedPassword = nil
    }

    // MARK: - Touch ID

    private func authenticateWithTouchID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock MacUninstaller admin access"
            )
        } catch {
            return false
        }
    }

    // MARK: - Get Password

    private func getAdminPassword() async throws -> String {
        // 1. Cached this session
        if let pw = Self.cachedPassword { return pw }

        // 2. Stored in Keychain — verify with Touch ID first
        if let stored = loadFromKeychain() {
            let touchOK = await authenticateWithTouchID()
            if touchOK {
                Self.cachedPassword = stored
                return stored
            }
            // Touch ID failed — still allow manual entry
        }

        // 3. Ask for password
        guard let pw = await askForPassword() else {
            throw UninstallError.cancelled
        }

        guard verifyPassword(pw) else {
            throw UninstallError.authFailed("Incorrect password")
        }

        saveToKeychain(password: pw)
        Self.cachedPassword = pw
        return pw
    }

    private func askForPassword() async -> String? {
        await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Administrator Password"
            alert.informativeText = "Enter your password to remove protected files.\n\nThis will be saved securely — next time you can use Touch ID."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
            input.placeholderString = "Password"
            alert.accessoryView = input
            alert.window.initialFirstResponder = input

            let response = alert.runModal()
            if response == .alertFirstButtonReturn && !input.stringValue.isEmpty {
                return input.stringValue
            }
            return nil
        }
    }

    private func verifyPassword(_ password: String) -> Bool {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/sudo")
        process.arguments = ["-S", "-v"]

        let input = Pipe()
        process.standardInput = input
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            input.fileHandleForWriting.write("\(password)\n".data(using: .utf8)!)
            input.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Uninstall

    func uninstall(paths: [URL], useTrash: Bool = true) async throws -> UninstallResult {
        var removed: [URL] = []
        var failed: [(URL, Error)] = []
        var freedBytes: Int64 = 0
        var needsEscalation: [(url: URL, size: Int64)] = []

        for path in paths {
            let resolved = path.resolvingSymlinksInPath().standardized.path
            let isBlocked = AppConstants.blockedPaths.contains { resolved.hasPrefix($0) }
            if isBlocked {
                failed.append((path, UninstallError.permissionDenied(path: resolved)))
                continue
            }
            guard fileManager.fileExists(atPath: resolved) else { continue }

            let size = itemSize(path)
            do {
                if useTrash {
                    try await trashItem(at: path)
                } else {
                    try fileManager.removeItem(at: path)
                }
                removed.append(path)
                freedBytes += size
            } catch {
                needsEscalation.append((url: path, size: size))
            }
        }

        if !needsEscalation.isEmpty {
            do {
                let pw = try await getAdminPassword()
                try deleteWithSudo(password: pw, items: needsEscalation)
                for item in needsEscalation {
                    removed.append(item.url)
                    freedBytes += item.size
                }
            } catch {
                for item in needsEscalation {
                    failed.append((item.url, error))
                }
            }
        }

        if !failed.isEmpty && removed.isEmpty {
            if let first = failed.first { throw first.1 }
        }
        if !failed.isEmpty && !removed.isEmpty {
            throw UninstallError.partialFailure(removed: removed, failed: failed)
        }

        return UninstallResult(removedPaths: removed, failedPaths: failed, totalFreedBytes: freedBytes)
    }

    private func trashItem(at url: URL) async throws {
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                DispatchQueue.main.async {
                    NSWorkspace.shared.recycle([url]) { _, error in
                        if let error { cont.resume(throwing: error) }
                        else { cont.resume() }
                    }
                }
            }
        } catch {
            var trash: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &trash)
        }
    }

    private func deleteWithSudo(password: String, items: [(url: URL, size: Int64)]) throws {
        let paths = items.compactMap { item -> String? in
            let canonical = item.url.resolvingSymlinksInPath().standardized.path
            let blocked = AppConstants.blockedPaths.contains { canonical.hasPrefix($0) }
            guard !blocked, FileManager.default.fileExists(atPath: canonical) else { return nil }
            return canonical
        }
        guard !paths.isEmpty else { return }

        let cmd = paths.map { "rm -rf '\($0.replacingOccurrences(of: "'", with: "'\\''"))'" }.joined(separator: "; ")

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/sudo")
        process.arguments = ["-S", "/bin/sh", "-c", cmd]

        let input = Pipe()
        let errPipe = Pipe()
        process.standardInput = input
        process.standardOutput = Pipe()
        process.standardError = errPipe

        try process.run()
        input.fileHandleForWriting.write("\(password)\n".data(using: .utf8)!)
        input.fileHandleForWriting.closeFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let err = String(data: errPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
            if err.contains("incorrect password") {
                clearKeychain()
                throw UninstallError.authFailed("Password incorrect. Please try again.")
            }
            throw UninstallError.authFailed(err.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func itemSize(_ url: URL) -> Int64 {
        var isDir: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDir) else { return 0 }
        if !isDir.boolValue {
            return Int64((try? fileManager.attributesOfItem(atPath: url.path))?[.size] as? UInt64 ?? 0)
        }
        guard let e = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey], options: []) else { return 0 }
        var total: Int64 = 0
        for case let f as URL in e { total += Int64((try? f.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0) }
        return total
    }
}
