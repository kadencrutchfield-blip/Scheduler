# Scheduler — a "find a common time" poll for iMessage

An iMessage app (like GamePigeon) that lives in the Messages app drawer.
Start a poll in any chat, add some possible times, and everyone taps the times
they're free. The bubble in the chat updates in place and shows the **best time**.

No accounts, no server: the poll and every vote travel inside the message itself.

## How it works in a chat

1. In Messages, tap **+** → **Scheduler** → **New Time Poll**.
2. Name the event (e.g. "Game night"), pick a duration, add a few times, tap **Send**.
3. Friends tap the bubble, enter their name, check the times that work, tap **Send my availability**.
4. The bubble shows the leading time and how many people can make it. Tap any time to change your answer.

## Run it on your iPhone

You need a Mac with Xcode 15+ (free Apple ID is enough for your own phone).

```bash
brew install xcodegen
xcodegen generate        # creates Scheduler.xcodeproj from project.yml
open Scheduler.xcodeproj
```

In Xcode:
1. Select the **Scheduler** target → *Signing & Capabilities* → pick your Team. Do the same for **SchedulerMessages**.
   If the bundle IDs are taken, change `com.kadencrutchfield.scheduler` in both targets (the extension's must start with the app's).
2. Plug in your iPhone, pick it as the run destination, and press ▶.
3. Open Messages → **+** → you'll see Scheduler in the app list.

To test without a phone, choose the **SchedulerMessages** scheme and run it on a simulator — Xcode
opens the Messages simulator with a fake two-person conversation.

## Sharing it with friends

Everyone who wants to vote needs the app installed. Options:
- **TestFlight** (up to 10,000 testers) — no Mac needed, see [TESTFLIGHT.md](TESTFLIGHT.md). Requires an Apple Developer Program membership ($99/yr).
- Free provisioning only installs on devices you plug into your own Mac (apps expire after 7 days).

## Project layout

| Path | What it is |
|---|---|
| `MessagesExtension/MessagesViewController.swift` | iMessage entry point; sends/updates the chat bubble |
| `MessagesExtension/Poll.swift` | Poll model + encoding into the message URL |
| `MessagesExtension/PollStore.swift` | UI state / actions |
| `MessagesExtension/Views.swift` | SwiftUI screens: home, create poll, vote |
| `MessagesExtension/CardRenderer.swift` | Draws the image shown in the bubble |
| `App/` | Small home-screen app with instructions (required container for the extension) |
| `project.yml` | XcodeGen project definition |
