import Foundation

/// Where things live on disk. Everything is under Documents, which the Files app shows.
enum Storage {
    static let documents = URL.documentsDirectory
    static let tracksDirectory = documents.appending(path: "tracks", directoryHint: .isDirectory)

    /// Names this run's files (`geolog-<stamp>.csv`, `tracks/track-<stamp>.csv`).
    static let sessionStamp: String = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }()
}
