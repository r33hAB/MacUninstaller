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
        case .permissionDenied(let path):
            return "Permission denied: \(path)"
        case .partialFailure(let removed, let failed):
            return "Removed \(removed.count) items, \(failed.count) failed"
        case .cancelled:
            return "Uninstall cancelled"
        case .authFailed(let msg):
            return "Authorization failed: \(msg)"
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

    /// Keychain service name for storing admin password
    private static let keychainService = "com.r33hab.macuninstall.admin"
    private static let keychainAccount = "admin-password"

    /// Cached password for this session
    private static var cachedPassword: String?

    // MARK: - Keychain

    /// Save password to Keychain (protected by Touch ID)
    private func saveToKeychain(password: String) {
        // Delete existing
        let deleteQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
        ]
        SecItemDelete(deleteQuery as CFDictionary)

        // Create access control requiring Touch ID
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlocked,
            .userPresence,
            nil
        ) else { return }

        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecValueData as String: password.data(using: .utf8)!,
            kSecAttrAccessControl as String: access,
                    ]
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        print("Keychain save status: \(addStatus) (\(addStatus == errSecSuccess ? "SUCCESS" : "FAILED"))")
    }

    /// Retrieve password from Keychain using Touch ID
    private func getFromKeychain() async -> String? {
        let context = LAContext()
        context.localizedReason = "Unlock admin access for MacUninstaller"

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecReturnData as String: true,
            kSecUseAuthenticationContext as String: context,
            kSecMatchLimit as String: kSecMatchLimitOne,
                    ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        print("Keychain read status: \(status) (\(status == errSecSuccess ? "SUCCESS" : "FAILED - \(status)"))")
        if status == errSecSuccess, let data = result as? Data,
           let password = String(data: data, encoding: .utf8) {
            return password
        }
        return nil
    }

    /// Check if we have a stored password in Keychain
    private func hasKeychainPassword() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.keychainService,
            kSecAttrAccount as String: Self.keychainAccount,
            kSecUseAuthenticationUI as String: kSecUseAuthenticationUISkip,
                    ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return status == errSecInteractionNotAllowed || status == errSecSuccess
    }

    // MARK: - Auth Flow

    /// Get admin password: Touch ID (from Keychain) → or ask once and save
    private func getAdminPassword() async throws -> String {
        // 1. Already cached this session
        if let cached = Self.cachedPassword { return cached }

        // 2. Try Keychain (triggers Touch ID)
        if hasKeychainPassword() {
            if let password = await getFromKeychain() {
                Self.cachedPassword = password
                return password
            }
            // Touch ID failed/cancelled — user can still enter manually
        }

        // 3. First time — ask for password via dialog, save to Keychain
        guard let password = await askForPassword() else {
            throw UninstallError.cancelled
        }

        // Verify password works
        let verified = verifyPassword(password)
        guard verified else {
            throw UninstallError.authFailed("Incorrect password")
        }

        // Save to Keychain for future Touch ID use
        saveToKeychain(password: password)
        Self.cachedPassword = password
        return password
    }

    /// Show a native password dialog
    private func askForPassword() async -> String? {
        return await MainActor.run {
            let alert = NSAlert()
            alert.messageText = "Administrator Password"
            alert.informativeText = "Enter your password to allow MacUninstaller to remove protected files.\n\nYour password will be saved securely and protected by Touch ID for future use."
            alert.alertStyle = .informational
            alert.addButton(withTitle: "OK")
            alert.addButton(withTitle: "Cancel")

            let input = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 260, height: 24))
            input.placeholderString = "Password"
            alert.accessoryView = input
            alert.window.initialFirstResponder = input

            let response = alert.runModal()
            if response == .alertFirstButtonReturn {
                return input.stringValue.isEmpty ? nil : input.stringValue
            }
            return nil
        }
    }

    /// Verify password by running a harmless sudo command
    private func verifyPassword(_ password: String) -> Bool {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/sudo")
        process.arguments = ["-S", "-v"]
        process.environment = ["PATH": "/usr/bin:/bin"]

        let inputPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = Pipe()
        process.standardError = Pipe()

        do {
            try process.run()
            inputPipe.fileHandleForWriting.write("\(password)\n".data(using: .utf8)!)
            inputPipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Uninstall

    func uninstall(
        paths: [URL],
        useTrash: Bool = true
    ) async throws -> UninstallResult {
        var removed: [URL] = []
        var failed: [(URL, Error)] = []
        var freedBytes: Int64 = 0
        var needsEscalation: [(url: URL, size: Int64)] = []

        for path in paths {
            let resolvedPath = path.resolvingSymlinksInPath().standardized.path

            let isBlocked = AppConstants.blockedPaths.contains { resolvedPath.hasPrefix($0) }
            if isBlocked {
                failed.append((path, UninstallError.permissionDenied(path: resolvedPath)))
                continue
            }

            guard fileManager.fileExists(atPath: resolvedPath) else {
                continue
            }

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
                let password = try await getAdminPassword()
                try deleteWithSudo(password: password, items: needsEscalation)
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

        return UninstallResult(
            removedPaths: removed,
            failedPaths: failed,
            totalFreedBytes: freedBytes
        )
    }

    private func trashItem(at url: URL) async throws {
        do {
            try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
                DispatchQueue.main.async {
                    NSWorkspace.shared.recycle([url]) { _, error in
                        if let error {
                            cont.resume(throwing: error)
                        } else {
                            cont.resume()
                        }
                    }
                }
            }
        } catch {
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
        }
    }

    /// Delete files using sudo with the stored password
    private func deleteWithSudo(password: String, items: [(url: URL, size: Int64)]) throws {
        let validPaths = items.compactMap { item -> String? in
            let canonical = item.url.resolvingSymlinksInPath().standardized.path
            let isBlocked = AppConstants.blockedPaths.contains { canonical.hasPrefix($0) }
            guard !isBlocked else { return nil }
            guard FileManager.default.fileExists(atPath: canonical) else { return nil }
            return canonical
        }

        guard !validPaths.isEmpty else { return }

        let commands = validPaths.map { path in
            let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
            return "rm -rf '\(escaped)'"
        }.joined(separator: "; ")

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/sudo")
        process.arguments = ["-S", "/bin/sh", "-c", commands]
        process.environment = ["PATH": "/usr/bin:/bin:/usr/sbin:/sbin"]

        let inputPipe = Pipe()
        let errPipe = Pipe()
        process.standardInput = inputPipe
        process.standardOutput = Pipe()
        process.standardError = errPipe

        try process.run()
        inputPipe.fileHandleForWriting.write("\(password)\n".data(using: .utf8)!)
        inputPipe.fileHandleForWriting.closeFile()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? ""
            if errorMsg.contains("incorrect password") {
                // Password changed — clear keychain and retry next time
                Self.cachedPassword = nil
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.keychainService,
                    kSecAttrAccount as String: Self.keychainAccount,
                ]
                SecItemDelete(deleteQuery as CFDictionary)
                throw UninstallError.authFailed("Password incorrect. Please try again.")
            }
            throw UninstallError.authFailed(errorMsg.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }

    private func itemSize(_ url: URL) -> Int64 {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else { return 0 }

        if !isDirectory.boolValue {
            let attrs = try? fileManager.attributesOfItem(atPath: url.path)
            return Int64(attrs?[.size] as? UInt64 ?? 0)
        }

        guard let enumerator = fileManager.enumerator(
            at: url, includingPropertiesForKeys: [.fileSizeKey], options: []
        ) else { return 0 }

        var total: Int64 = 0
        for case let fileURL as URL in enumerator {
            let values = try? fileURL.resourceValues(forKeys: [.fileSizeKey])
            total += Int64(values?.fileSize ?? 0)
        }
        return total
    }
}
