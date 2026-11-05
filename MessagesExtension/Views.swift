import SwiftUI

private let accent = Color(red: 0.10, green: 0.45, blue: 0.95)
private let good = Color(red: 0.20, green: 0.70, blue: 0.45)

struct RootView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        Group {
            switch store.screen {
            case .home:
                HomeView(store: store)
            case .create:
                CreatePollView(store: store)
            case .vote:
                if store.isExpanded {
                    VoteView(store: store)
                } else {
                    CompactPollView(store: store)
                }
            }
        }
        .tint(accent)
    }
}

// MARK: - Home (compact drawer)

struct HomeView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40, weight: .semibold))
                .foregroundStyle(accent)
            Text("Find a time that works for everyone")
                .font(.headline)
                .multilineTextAlignment(.center)
            Button {
                store.startCreating()
            } label: {
                Label("New Time Poll", systemImage: "plus")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Create

struct CreatePollView: View {
    @ObservedObject var store: PollStore

    @State private var title = ""
    @State private var slots: [Date] = []
    @State private var pending = CreatePollView.nextHour()
    @State private var duration = 60

    private let durations = [30, 60, 120, 180]

    static func nextHour() -> Date {
        let cal = Calendar.current
        let now = Date()
        let start = cal.date(bySetting: .minute, value: 0, of: now) ?? now
        return cal.date(byAdding: .hour, value: start <= now ? 1 : 0, to: start) ?? now
    }

    private var canSend: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty && !slots.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button("Cancel") { store.cancelCreating() }
                Spacer()
                Text("New Poll").font(.headline)
                Spacer()
                Button("Send") {
                    store.create(title: title, slots: slots, durationMinutes: duration)
                }
                .bold()
                .disabled(!canSend)
            }
            .padding()

            Form {
                Section("Event") {
                    TextField("e.g. Dinner, Game night, Study group", text: $title)
                }

                Section("How long?") {
                    Picker("Duration", selection: $duration) {
                        ForEach(durations, id: \.self) { m in
                            Text(m < 60 ? "\(m)m" : "\(m / 60)h").tag(m)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    DatePicker("Time", selection: $pending, displayedComponents: [.date, .hourAndMinute])
                    HStack {
                        Button {
                            add(pending)
                        } label: {
                            Label("Add this time", systemImage: "plus.circle.fill")
                        }
                        Spacer()
                        if let last = slots.last {
                            Button("Same time +1 day") {
                                add(Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last)
                            }
                            .font(.footnote)
                        }
                    }
                    .buttonStyle(.borderless)
                } header: {
                    Text("Time options")
                } footer: {
                    Text("Add every time that could work. Friends will tap the ones they're free for.")
                }

                if !slots.isEmpty {
                    Section("\(slots.count) option\(slots.count == 1 ? "" : "s")") {
                        ForEach(slots, id: \.self) { slot in
                            Text(Formatters.range(start: slot, minutes: duration))
                        }
                        .onDelete { slots.remove(atOffsets: $0) }
                    }
                }
            }
        }
    }

    private func add(_ date: Date) {
        guard !slots.contains(date) else { return }
        slots.append(date)
        slots.sort()
        pending = date
    }
}

// MARK: - Vote (expanded)

struct VoteView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        if let poll = store.poll {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(poll.title).font(.title.bold())
                            Text(poll.respondentCount == 0
                                 ? "Be the first to respond — tap every time you're free."
                                 : "\(poll.respondentCount) responded so far. Tap every time you're free.")
                                .foregroundStyle(.secondary)
                        }

                        HStack {
                            Image(systemName: "person.crop.circle")
                                .foregroundStyle(.secondary)
                            TextField("Your name", text: $store.myName)
                                .textContentType(.givenName)
                        }
                        .padding(12)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 12))

                        ForEach(poll.slots.indices, id: \.self) { i in
                            SlotRow(poll: poll,
                                    index: i,
                                    selected: store.mySelection.contains(i),
                                    isBest: poll.bestSlots.contains(i)) {
                                store.toggle(i)
                            }
                        }
                    }
                    .padding()
                }

                Button {
                    store.submitVote()
                } label: {
                    Text(store.hasResponded ? "Update my availability" : "Send my availability")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.myName.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding()
            }
        }
    }
}

struct SlotRow: View {
    let poll: Poll
    let index: Int
    let selected: Bool
    let isBest: Bool
    let onTap: () -> Void

    var body: some View {
        let count = poll.count(for: index)
        let total = max(poll.respondentCount, 1)
        let names = poll.voterNames(for: index)

        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? good : .secondary)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(poll.timeText(for: index))
                            .font(.body.weight(.semibold))
                            .foregroundStyle(.primary)
                        if isBest {
                            Text("BEST")
                                .font(.caption2.bold())
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Color.yellow.opacity(0.35), in: Capsule())
                                .foregroundStyle(.primary)
                        }
                        Spacer()
                        Text("\(count)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.secondary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color(.tertiarySystemFill))
                            Capsule().fill(isBest ? good : accent)
                                .frame(width: geo.size.width * CGFloat(count) / CGFloat(total))
                        }
                    }
                    .frame(height: 6)

                    if !names.isEmpty {
                        Text(names.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(selected ? good.opacity(0.12) : Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(selected ? good : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Vote (compact)

struct CompactPollView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        if let poll = store.poll {
            VStack(alignment: .leading, spacing: 10) {
                Text(poll.title).font(.headline)
                Text(poll.summaryLine)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Button {
                    store.requestExpand()
                } label: {
                    Text(store.hasResponded ? "Change my answer" : "Pick my times")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }
}
