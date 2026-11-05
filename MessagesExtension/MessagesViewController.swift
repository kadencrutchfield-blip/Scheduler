import UIKit
import Messages
import SwiftUI

/// Entry point of the iMessage app (the thing that shows up in the Messages app drawer).
final class MessagesViewController: MSMessagesAppViewController {
    private let store = PollStore()

    override func viewDidLoad() {
        super.viewDidLoad()

        let host = UIHostingController(rootView: RootView(store: store))
        addChild(host)
        host.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(host.view)
        NSLayoutConstraint.activate([
            host.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            host.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            host.view.topAnchor.constraint(equalTo: view.topAnchor),
            host.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
        host.didMove(toParent: self)

        store.requestExpand = { [weak self] in self?.requestPresentationStyle(.expanded) }
        store.requestCompact = { [weak self] in self?.requestPresentationStyle(.compact) }
        store.sendPoll = { [weak self] poll, isNew in self?.send(poll, isNew: isNew) }
    }

    // MARK: - Conversation lifecycle

    override func willBecomeActive(with conversation: MSConversation) {
        super.willBecomeActive(with: conversation)
        store.isExpanded = presentationStyle == .expanded
        store.load(conversation: conversation)
    }

    override func didSelect(_ message: MSMessage, conversation: MSConversation) {
        super.didSelect(message, conversation: conversation)
        store.load(conversation: conversation)
    }

    override func didReceive(_ message: MSMessage, conversation: MSConversation) {
        super.didReceive(message, conversation: conversation)
        if let url = message.url, let poll = Poll(url: url) {
            store.receive(poll)
        }
    }

    override func willTransition(to presentationStyle: MSMessagesAppPresentationStyle) {
        super.willTransition(to: presentationStyle)
        store.isExpanded = presentationStyle == .expanded
    }

    // MARK: - Sending

    private func send(_ poll: Poll, isNew: Bool) {
        guard let conversation = activeConversation else { return }

        // Reusing the session makes Messages update the existing bubble
        // instead of stacking a brand new one for every vote.
        let session = isNew ? MSSession() : (conversation.selectedMessage?.session ?? MSSession())
        let message = MSMessage(session: session)
        message.url = poll.url

        let layout = MSMessageTemplateLayout()
        layout.image = CardRenderer.image(for: poll)
        layout.caption = poll.title
        layout.subcaption = poll.summaryLine
        layout.trailingSubcaption = poll.respondentCount == 1 ? "1 response" : "\(poll.respondentCount) responses"
        message.layout = layout
        message.summaryText = isNew ? "📅 \(poll.title): when are you free?" : "📅 Updated availability for \(poll.title)"

        if isNew {
            // Put it in the compose field so the creator can add a note and hit send.
            conversation.insert(message) { error in
                if let error { print("Insert failed: \(error)") }
            }
        } else {
            conversation.send(message) { error in
                if error != nil {
                    // Fall back to dropping it in the compose field.
                    DispatchQueue.main.async { conversation.insert(message, completionHandler: nil) }
                }
            }
        }
        requestPresentationStyle(.compact)
    }
}
