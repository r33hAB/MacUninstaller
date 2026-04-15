import Foundation

final class SIPChecker {
    func isSIPEnabled() -> Bool {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/csrutil")
        process.arguments = ["status"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return output.contains("enabled")
        } catch {
            return true
        }
    }
}
