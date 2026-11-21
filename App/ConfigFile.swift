import Foundation
import GeoLogCore

/// A JSON settings file in Documents. Written with defaults on first use so there is
/// something to edit from the Files app.
struct ConfigFile<Value: JSONConfig> {
    let name: String
    private var url: URL { Storage.documents.appending(path: name) }

    func load() -> Value {
        if let data = try? Data(contentsOf: url) { return Value.from(jsonData: data) }
        save(.default)
        return .default
    }

    func save(_ value: Value) {
        try? value.jsonData().write(to: url)
    }
}
