import Foundation
import Messages

/// UI state shared between the Messages view controller and the SwiftUI views.
final class PollStore: ObservableObject {
    enum Screen { case home, create, vote }

    @Published var screen: Screen = .home
    @Published var poll: Poll?
    @Published var isExpanded = false
    /// The times the local user has ticked (not sent until they tap Send).
    @Published var mySelection: Set<Int> = []
    @Published var myName: String {
        didSet { UserDefaults.standard.set(myName, forKey: "myName") }
    }

    private(set) var myID = ""

    // Hooks wired up by MessagesViewController.
    var requestExpand: () -> Void = {}
    var requestCompact: () -> Void = {}
    var sendPoll: (_ poll: Poll, _ isNew: Bool) -> Void = { _, _ in }

    init() {
        myName = UserDefaults.standard.string(forKey: "myName") ?? ""
    }

    var hasResponded: Bool { poll?.votes[myID] != nil }

    func load(conversation: MSConversation) {
        myID = conversation.localParticipantIdentifier.uuidString
        if let url = conversation.selectedMessage?.url, let p = Poll(url: url) {
            poll = p
            mySelection = Set(p.votes[myID] ?? [])
            screen = .vote
        } else {
            poll = nil
            mySelection = []
            screen = .home
        }
    }

    /// Someone else updated the poll while we have it open.
    func receive(_ incoming: Poll) {
        guard poll?.id == incoming.id else { return }
        poll = incoming // keep the user's in-progress `mySelection`
    }

    func startCreating() {
        screen = .create
        requestExpand()
    }

    func cancelCreating() {
        screen = .home
        requestCompact()
    }

    func create(title: String, slots: [Date], durationMinutes: Int) {
        let poll = Poll(title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                        slots: slots.sorted(),
                        durationMinutes: durationMinutes)
        sendPoll(poll, true)
        screen = .home
    }

    func toggle(_ slot: Int) {
        if mySelection.contains(slot) { mySelection.remove(slot) } else { mySelection.insert(slot) }
    }

    func submitVote() {
        guard var p = poll else { return }
        p.votes[myID] = mySelection.sorted()
        let name = myName.trimmingCharacters(in: .whitespacesAndNewlines)
        p.names[myID] = name.isEmpty ? "Someone" : name
        poll = p
        sendPoll(p, false)
    }
}
