import SwiftUI
import UIKit

private let brandGradient = LinearGradient(
    colors: [Color(red: 0.20, green: 0.78, blue: 0.55), Color(red: 0.10, green: 0.45, blue: 0.95)],
    startPoint: .topLeading, endPoint: .bottomTrailing)

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
    }
}

// MARK: - Shared pieces

/// Rounded-square app glyph, like a home-screen icon.
struct AppGlyph: View {
    var size: CGFloat = 52

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
            .fill(brandGradient)
            .frame(width: size, height: size)
            .overlay(
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: size * 0.48, weight: .semibold))
                    .foregroundStyle(.white)
            )
    }
}

/// A little page-a-day tile in the style of the Calendar app icon.
struct CalendarTile: View {
    let date: Date
    var size: CGFloat = 56

    var body: some View {
        VStack(spacing: 0) {
            Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                .font(.system(size: size * 0.2, weight: .semibold))
                .foregroundStyle(.red)
            Text(date.formatted(.dateTime.day()))
                .font(.system(size: size * 0.48, weight: .regular))
                .foregroundStyle(.primary)
                .monospacedDigit()
        }
        .frame(width: size, height: size)
        .background(Color(.secondarySystemGroupedBackground),
                    in: RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                .strokeBorder(Color(.separator).opacity(0.5), lineWidth: 0.5)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Formatters.dayLong.string(from: date))
    }
}

// MARK: - Home (compact drawer)

struct HomeView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        VStack(spacing: 18) {
            Spacer(minLength: 0)
            HStack(spacing: 14) {
                AppGlyph(size: 52)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Scheduler")
                        .font(.title3.weight(.semibold))
                    Text("Find a time that works for everyone.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            Button {
                store.startCreating()
            } label: {
                Label("New Time Poll", systemImage: "plus")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Create

struct CreatePollView: View {
    @ObservedObject var store: PollStore

    @State private var title = ""
    @State private var slots: [Date] = []
    @State private var pending = CreatePollView.nextHour()
    @State private var duration = 60

    private let durations = [30, 60, 90, 120, 180]

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
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title, prompt: Text("Game night, dinner, study group…"))
                        .textInputAutocapitalization(.sentences)
                    Picker("Duration", selection: $duration) {
                        ForEach(durations, id: \.self) { m in
                            Text(Formatters.duration(m)).tag(m)
                        }
                    }
                } header: {
                    Text("Event")
                }

                Section {
                    DatePicker("Starts", selection: $pending, displayedComponents: [.date, .hourAndMinute])
                    Button {
                        add(pending)
                    } label: {
                        Label("Add Time", systemImage: "plus.circle.fill")
                    }
                    if let last = slots.last {
                        Button {
                            add(Calendar.current.date(byAdding: .day, value: 1, to: last) ?? last)
                        } label: {
                            Label("Same Time Next Day", systemImage: "arrow.forward.circle")
                        }
                    }
                } header: {
                    Text("Add Times")
                } footer: {
                    Text("Add every time that could work. Friends tap the ones they're free.")
                }

                if !slots.isEmpty {
                    Section {
                        ForEach(slots, id: \.self) { slot in
                            HStack(spacing: 12) {
                                CalendarTile(date: slot, size: 40)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(Formatters.dayLong.string(from: slot))
                                    Text(Formatters.timeRange(start: slot, minutes: duration))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .onDelete { slots.remove(atOffsets: $0) }
                    } header: {
                        Text(slots.count == 1 ? "1 Option" : "\(slots.count) Options")
                    }
                }
            }
            .navigationTitle("New Poll")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { store.cancelCreating() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Send") {
                        store.create(title: title, slots: slots, durationMinutes: duration)
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSend)
                }
            }
        }
    }

    private func add(_ date: Date) {
        guard !slots.contains(date) else { return }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation {
            slots.append(date)
            slots.sort()
        }
        pending = date
    }
}

// MARK: - Vote (expanded)

struct VoteView: View {
    @ObservedObject var store: PollStore

    private var nameMissing: Bool {
        store.myName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        if let poll = store.poll {
            NavigationStack {
                List {
                    Section {
                        PollHeader(poll: poll)
                    }

                    Section {
                        TextField("Your Name", text: $store.myName)
                            .textContentType(.givenName)
                    } header: {
                        Text("Responding As")
                    }

                    ForEach(poll.slotsByDay) { group in
                        Section {
                            ForEach(group.indices, id: \.self) { i in
                                SlotRow(poll: poll,
                                        index: i,
                                        selected: store.mySelection.contains(i),
                                        isBest: poll.bestSlots.contains(i)) {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    withAnimation(.easeInOut(duration: 0.2)) { store.toggle(i) }
                                }
                            }
                        } header: {
                            Text(Formatters.dayLong.string(from: group.day))
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .navigationTitle(poll.title)
                .navigationBarTitleDisplayMode(.inline)
                .safeAreaInset(edge: .bottom) {
                    VStack(spacing: 6) {
                        Button {
                            UINotificationFeedbackGenerator().notificationOccurred(.success)
                            store.submitVote()
                        } label: {
                            Text(store.hasResponded ? "Update Availability" : "Send Availability")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.capsule)
                        .controlSize(.large)
                        .disabled(nameMissing)

                        if nameMissing {
                            Text("Enter your name to send.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(.bar)
                }
            }
        }
    }
}

struct PollHeader: View {
    let poll: Poll

    var body: some View {
        HStack(spacing: 14) {
            if let date = poll.featuredDate {
                CalendarTile(date: date, size: 56)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(poll.title)
                    .font(.title3.weight(.semibold))
                if let best = poll.bestSlots.first {
                    Label {
                        Text(Formatters.day.string(from: poll.slots[best]) + ", "
                             + Formatters.timeRange(start: poll.slots[best], minutes: poll.durationMinutes))
                    } icon: {
                        Image(systemName: "star.fill").foregroundStyle(.yellow)
                    }
                    .font(.subheadline)
                }
                Text(poll.respondentCount == 0
                     ? "No responses yet"
                     : "\(poll.respondentCount) responded · \(Formatters.duration(poll.durationMinutes))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
            HStack(alignment: .center, spacing: 12) {
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(selected ? Color.green : Color(.tertiaryLabel))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text(Formatters.timeRange(start: poll.slots[index], minutes: poll.durationMinutes))
                            .foregroundStyle(.primary)
                        if isBest {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundStyle(.yellow)
                                .accessibilityLabel("Best time")
                        }
                        Spacer(minLength: 8)
                        HStack(spacing: 3) {
                            Image(systemName: "person.fill").font(.caption)
                            Text("\(count)").monospacedDigit()
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    ProgressView(value: Double(count), total: Double(total))
                        .tint(isBest ? .green : .accentColor)

                    if !names.isEmpty {
                        Text(names.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Vote (compact)

struct CompactPollView: View {
    @ObservedObject var store: PollStore

    var body: some View {
        if let poll = store.poll {
            VStack(spacing: 16) {
                Spacer(minLength: 0)
                HStack(spacing: 14) {
                    if let date = poll.featuredDate {
                        CalendarTile(date: date, size: 52)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(poll.title).font(.headline)
                        Text(poll.respondentCount == 0
                             ? "\(poll.slots.count) times to choose from"
                             : "\(poll.respondentCount) responded")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }
                Button {
                    store.requestExpand()
                } label: {
                    Text(store.hasResponded ? "Change My Answer" : "Pick My Times")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .controlSize(.large)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
        }
    }
}
