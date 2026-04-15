import Foundation
import CommonCrypto

final class DuplicateDetector {

    func groupBySize(_ files: [ScannedFile]) -> [[ScannedFile]] {
        let grouped = Dictionary(grouping: files, by: \.size)
        return grouped.values.filter { $0.count > 1 }
    }

    func findDuplicates(in sizeGroup: [ScannedFile]) -> [[ScannedFile]] {
        var hashGroups: [Data: [ScannedFile]] = [:]
        for file in sizeGroup {
            guard let headHash = hashHead(of: file.path) else { continue }
            hashGroups[headHash, default: []].append(file)
        }
        return hashGroups.values.filter { $0.count > 1 }
    }

    func confirmDuplicates(in candidates: [ScannedFile]) -> [[ScannedFile]] {
        var hashGroups: [Data: [ScannedFile]] = [:]
        for file in candidates {
            guard let fullHash = hashFull(of: file.path) else { continue }
            hashGroups[fullHash, default: []].append(file)
        }
        return hashGroups.values.filter { $0.count > 1 }
    }

    func isNearDuplicate(_ name1: String, _ name2: String) -> Bool {
        let base1 = stripDuplicateSuffix(name1)
        let base2 = stripDuplicateSuffix(name2)
        return base1 == base2 && name1 != name2
    }

    func findNearDuplicates(in files: [ScannedFile]) -> [[ScannedFile]] {
        var groups: [String: [ScannedFile]] = [:]
        for file in files {
            let base = stripDuplicateSuffix(file.name)
            groups[base, default: []].append(file)
        }
        return groups.values.filter { $0.count > 1 }
    }

    func checkExtractedArchive(archivePath: URL, siblingNames: [String]) -> Bool {
        let archiveName = archivePath.deletingPathExtension().lastPathComponent
        return siblingNames.contains(archiveName)
    }

    private func stripDuplicateSuffix(_ name: String) -> String {
        let ext = (name as NSString).pathExtension
        var base = (name as NSString).deletingPathExtension

        let patterns = [
            #"\s*\(\d+\)$"#,
            #"\s*-\s*Copy$"#,
            #"\s*copy$"#,
            #"-\d+$"#,
            #"\s+\d+$"#,
        ]

        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let range = NSRange(base.startIndex..., in: base)
                base = regex.stringByReplacingMatches(in: base, range: range, withTemplate: "")
            }
        }

        return ext.isEmpty ? base : "\(base).\(ext)"
    }

    private func hashHead(of url: URL, bytes: Int = 4096) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { handle.closeFile() }
        let data = handle.readData(ofLength: bytes)
        return sha256(data)
    }

    private func hashFull(of url: URL) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { handle.closeFile() }

        var context = CC_SHA256_CTX()
        CC_SHA256_Init(&context)

        let bufferSize = 65536 // 64KB chunks
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: bufferSize)
            if data.isEmpty { return false }
            data.withUnsafeBytes {
                _ = CC_SHA256_Update(&context, $0.baseAddress, CC_LONG(data.count))
            }
            return true
        }) {}

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256_Final(&hash, &context)
        return Data(hash)
    }

    private func sha256(_ data: Data) -> Data {
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        return Data(hash)
    }
}
