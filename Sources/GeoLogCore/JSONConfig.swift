import Foundation

/// A small settings type stored as pretty JSON that the user may edit by hand.
public protocol JSONConfig: Codable {
    static var `default`: Self { get }
}

public extension JSONConfig {
    func jsonData() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(self)
    }

    /// A malformed file yields defaults rather than crashing mid-walk.
    static func from(jsonData data: Data) -> Self {
        (try? JSONDecoder().decode(Self.self, from: data)) ?? .default
    }
}
