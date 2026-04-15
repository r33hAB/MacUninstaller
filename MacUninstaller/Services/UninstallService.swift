import Foundation
import AppKit
import LocalAuthentication

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

    /// Once authenticated via Touch ID this session, skip future prompts
    private static var authenticated = false

    /// Authenticate via Touch ID. Only prompts once per session.
    private func authenticate() async throws {
        if Self.authenticated { return }

        let context = LAContext()
        var error: NSError?

        // Try biometrics first, fall back to device passcode
        let policy: LAPolicy = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
            ? .deviceOwnerAuthenticationWithBiometrics
            : .deviceOwnerAuthentication

        let success = try await context.evaluatePolicy(
            policy,
            localizedReason: "MacUninstaller needs permission to remove protected files"
        )

        if success {
            Self.authenticated = true
        } else {
            throw UninstallError.cancelled
        }
    }

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

        // Authenticate once via Touch ID, then delete all escalated paths
        if !needsEscalation.isEmpty {
            do {
                try await authenticate()
                try deleteWithAdmin(items: needsEscalation)
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

    /// After Touch ID auth, delete files using AppleScript with admin privileges.
    /// The user already authenticated via Touch ID — this uses their auth session.
    private func deleteWithAdmin(items: [(url: URL, size: Int64)]) throws {
        let validPaths = items.compactMap { item -> String? in
            let canonical = item.url.resolvingSymlinksInPath().standardized.path
            let isBlocked = AppConstants.blockedPaths.contains { canonical.hasPrefix($0) }
            guard !isBlocked else { return nil }
            guard FileManager.default.fileExists(atPath: canonical) else { return nil }
            return canonical
        }

        guard !validPaths.isEmpty else { return }

        // Build individual rm commands
        let commands = validPaths.map { path in
            let escaped = path.replacingOccurrences(of: "'", with: "'\\''")
            return "rm -rf '\(escaped)'"
        }.joined(separator: "; ")

        // Use AuthorizationExecuteWithPrivileges via C bridge
        // Create auth ref without interaction since user already did Touch ID
        var ref: AuthorizationRef?
        AuthorizationCreate(nil, nil, [], &ref)
        guard let authRef = ref else {
            throw UninstallError.authFailed("Could not create authorization")
        }

        let cFlag = strdup("-c")!
        let cScript = strdup(commands)!
        let cArgs: [UnsafePointer<CChar>?] = [
            UnsafePointer(cFlag),
            UnsafePointer(cScript),
            nil
        ]
        defer {
            free(cFlag)
            free(cScript)
        }

        var mutableArgs = cArgs
        let status = mutableArgs.withUnsafeMutableBufferPointer { buf in
            AuthHelperExecute(authRef, "/bin/sh", buf.baseAddress!)
        }

        AuthorizationFree(authRef, [])

        // If AuthHelperExecute fails (no pre-auth), it will show its own dialog
        // That's acceptable as a fallback — user already saw Touch ID
        if status != errAuthorizationSuccess && status != errAuthorizationCanceled {
            // Try osascript as last resort
            try deleteWithOsascript(commands: commands)
        } else if status == errAuthorizationCanceled {
            throw UninstallError.cancelled
        }
    }

    private func deleteWithOsascript(commands: String) throws {
        let escaped = commands
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/osascript")
        process.arguments = ["-e", "do shell script \"\(escaped)\" with administrator privileges"]

        let errPipe = Pipe()
        process.standardError = errPipe
        process.standardOutput = Pipe()

        try process.run()
        process.waitUntilExit()

        if process.terminationStatus != 0 {
            let errorData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMsg = String(data: errorData, encoding: .utf8) ?? ""
            if errorMsg.contains("-128") || errorMsg.contains("User canceled") {
                throw UninstallError.cancelled
            }
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
