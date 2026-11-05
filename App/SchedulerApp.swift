import SwiftUI

/// The home-screen app. The real action happens inside Messages, so this
/// just explains how to use it.
@main
struct SchedulerApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56, weight: .semibold))
                .foregroundStyle(.blue)
            Text("Scheduler lives in Messages")
                .font(.largeTitle.bold())
            VStack(alignment: .leading, spacing: 14) {
                step(1, "Open a group chat in Messages.")
                step(2, "Tap the + (or App Store icon) next to the text box and choose Scheduler.")
                step(3, "Tap New Time Poll, name the event, and add a few times.")
                step(4, "Send it. Everyone taps the times they're free — the bubble updates and shows the best time.")
            }
            Spacer()
        }
        .padding(28)
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(n)")
                .font(.headline)
                .frame(width: 28, height: 28)
                .background(Circle().fill(Color.blue.opacity(0.15)))
            Text(text)
        }
    }
}
