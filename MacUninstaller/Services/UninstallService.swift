import Foundation
import Security
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

    /// Cached authorization ref — persists for the app's lifetime.
    /// User enters password once, reused for every admin operation until quit.
    private static var authRef: AuthorizationRef?

    /// Whether user has authenticated this session (Touch ID or password)
    private static var isAuthenticated = false

    /// Authenticate and get authorization ref.
    /// Tries Touch ID first, creates auth ref without interaction if Touch ID succeeds.
    /// Falls back to system password dialog if Touch ID unavailable.
    private func authenticateAndAuthorize() async throws -> AuthorizationRef {
        if let existing = Self.authRef { return existing }

        // Try Touch ID first
        let usedTouchID = await tryTouchID()

        // Create authorization ref
        var ref: AuthorizationRef?
        let createStatus = AuthorizationCreate(nil, nil, [], &ref)
        guard createStatus == errAuthorizationSuccess, let authRef = ref else {
            throw UninstallError.authFailed("Could not create authorization reference")
        }

        let rightName = kAuthorizationRightExecute
        var item = rightName.withCString { cStr in
            AuthorizationItem(name: cStr, valueLength: 0, value: nil, flags: 0)
        }

        let status = withUnsafeMutablePointer(to: &item) { itemPtr in
            var rights = AuthorizationRights(count: 1, items: itemPtr)
            // If Touch ID succeeded, don't show password dialog (no interactionAllowed)
            // If Touch ID failed/unavailable, show the system password dialog
            let flags: AuthorizationFlags = usedTouchID
                ? [.preAuthorize, .extendRights]
                : [.interactionAllowed, .preAuthorize, .extendRights]
            return AuthorizationCopyRights(authRef, &rights, nil, flags, nil)
        }

        if status == errAuthorizationCanceled {
            AuthorizationFree(authRef, [])
            throw UninstallError.cancelled
        }

        // If non-interactive auth failed (Touch ID doesn't grant sudo),
        // fall back to interactive
        if status != errAuthorizationSuccess && usedTouchID {
            let retryStatus = withUnsafeMutablePointer(to: &item) { itemPtr in
                var rights = AuthorizationRights(count: 1, items: itemPtr)
                let flags: AuthorizationFlags = [.interactionAllowed, .preAuthorize, .extendRights]
                return AuthorizationCopyRights(authRef, &rights, nil, flags, nil)
            }

            if retryStatus == errAuthorizationCanceled {
                AuthorizationFree(authRef, [])
                throw UninstallError.cancelled
            }

            guard retryStatus == errAuthorizationSuccess else {
                AuthorizationFree(authRef, [])
                throw UninstallError.authFailed("Authorization denied")
            }
        } else if status != errAuthorizationSuccess {
            AuthorizationFree(authRef, [])
            throw UninstallError.authFailed("Authorization denied (status: \(status))")
        }

        Self.authRef = authRef
        return authRef
    }

    /// Try Touch ID authentication. Returns true if succeeded.
    private func tryTouchID() async -> Bool {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return false
        }

        do {
            return try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "MacUninstaller needs to remove protected files"
            )
        } catch {
            return false
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

            // Try user-level first
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

        // Escalate all failures with one auth (Touch ID → password fallback)
        if !needsEscalation.isEmpty {
            do {
                let authRef = try await authenticateAndAuthorize()
                try executePrivileged(authRef: authRef, items: needsEscalation)
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
        // Try NSWorkspace.recycle first — respects App Management permission
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
            // Fallback to FileManager
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
        }
    }

    /// Run rm -rf with admin privileges using the cached AuthorizationRef.
    /// Uses AuthorizationExecuteWithPrivileges (deprecated but functional).
    private func executePrivileged(authRef: AuthorizationRef, items: [(url: URL, size: Int64)]) throws {
        // Validate and canonicalize all paths first
        let validPaths = items.compactMap { item -> String? in
            let canonical = item.url.resolvingSymlinksInPath().standardized.path
            let isBlocked = AppConstants.blockedPaths.contains { canonical.hasPrefix($0) }
            guard !isBlocked else { return nil }
            guard FileManager.default.fileExists(atPath: canonical) else { return nil }
            return canonical
        }

        guard !validPaths.isEmpty else { return }

        let script = validPaths.map { path in
            path.replacingOccurrences(of: "'", with: "'\\''")
        }.map { "rm -rf '\($0)'" }.joined(separator: "; ")

        // Use C bridge to call AuthorizationExecuteWithPrivileges
        let cFlag = strdup("-c")!
        let cScript = strdup(script)!
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

        guard status == errAuthorizationSuccess else {
            if status == errAuthorizationCanceled {
                throw UninstallError.cancelled
            }
            throw UninstallError.authFailed("Privileged execution failed (status: \(status))")
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
