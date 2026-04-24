import Foundation
import Darwin

struct SystemInfoService {

    static func getInfo() -> String {
        var lines: [String] = []

        #if arch(arm64)
        // Apple Silicon: "Apple M1" / "Apple M2 Pro" など
        lines.append(cpuBrand() ?? "Apple Silicon")
        #else
        lines.append("Intel")
        #endif

        lines.append(osVersionString())
        return lines.joined(separator: "\n")
    }

    /// sysctlbyname("machdep.cpu.brand_string") で CPU 名を取得
    private static func cpuBrand() -> String? {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        guard size > 0 else { return nil }
        var buffer = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &buffer, &size, nil, 0)
        let s = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return s.isEmpty ? nil : s
    }

    private static func osVersionString() -> String {
        let v = ProcessInfo.processInfo.operatingSystemVersion
        let verStr = "\(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"

        let codeName: String
        switch v.majorVersion {
        case 13: codeName = "Ventura"
        case 14: codeName = "Sonoma"
        case 15: codeName = "Sequoia"
        case 16: codeName = "Tahoe"
        default:  codeName = ""
        }

        let osName = "macOS"
        return codeName.isEmpty ? "\(osName) \(verStr)" : "\(osName) \(codeName) \(verStr)"
    }
}
