import Foundation

/// A "find a common time" poll. The whole poll (options + everyone's votes)
/// is encoded into the iMessage bubble's URL, so no server is needed —
/// every time someone responds, the bubble is updated in place.
struct Poll: Codable, Equatable {
    var id: UUID = UUID()
    var title: String
    /// Candidate start times.
    var slots: [Date]
    var durationMinutes: Int
    /// participant id -> indices into `slots` that work for them.
    var votes: [String: [Int]] = [:]
    /// participant id -> display name they typed.
    var names: [String: String] = [:]

    var respondentCount: Int { votes.count }

    func count(for slot: Int) -> Int {
        votes.values.filter { $0.contains(slot) }.count
    }

    func voterNames(for slot: Int) -> [String] {
        votes.filter { $0.value.contains(slot) }
            .map { names[$0.key] ?? "Someone" }
            .sorted()
    }

    /// Indices of the slot(s) with the most "yes" votes (empty if nobody voted yet).
    var bestSlots: [Int] {
        let counts = slots.indices.map { count(for: $0) }
        guard let top = counts.max(), top > 0 else { return [] }
        return slots.indices.filter { counts[$0] == top }
    }

    func timeText(for slot: Int) -> String {
        Formatters.range(start: slots[slot], minutes: durationMinutes)
    }

    var summaryLine: String {
        guard let best = bestSlots.first else { return "Tap to pick the times you're free" }
        let n = count(for: best)
        return "Best: \(timeText(for: best)) (\(n)/\(respondentCount))"
    }
}

// MARK: - URL encoding

extension Poll {
    private static let queryKey = "poll"

    var url: URL? {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .sortedKeys
        guard let data = try? encoder.encode(self) else { return nil }
        var components = URLComponents()
        components.queryItems = [URLQueryItem(name: Self.queryKey, value: data.base64URLEncodedString())]
        return components.url
    }

    init?(url: URL) {
        guard
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
            let value = components.queryItems?.first(where: { $0.name == Self.queryKey })?.value,
            let data = Data(base64URLEncoded: value)
        else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        guard let poll = try? decoder.decode(Poll.self, from: data) else { return nil }
        self = poll
    }
}

extension Data {
    func base64URLEncodedString() -> String {
        base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    init?(base64URLEncoded string: String) {
        var s = string
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while s.count % 4 != 0 { s += "=" }
        self.init(base64Encoded: s)
    }
}

// MARK: - Formatting

enum Formatters {
    static let day: DateFormatter = {
        let f = DateFormatter()
        f.setLocalizedDateFormatFromTemplate("EEEMMMd")
        return f
    }()

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .none
        f.timeStyle = .short
        return f
    }()

    static func range(start: Date, minutes: Int) -> String {
        let end = start.addingTimeInterval(TimeInterval(minutes * 60))
        return "\(day.string(from: start)) · \(time.string(from: start)) – \(time.string(from: end))"
    }
}
