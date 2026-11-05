# Getting Scheduler on your iPhone with TestFlight (no Mac needed)

GitHub builds the app on its own Macs and uploads it to Apple. You set up the
Apple side once on the website, then press a button.

## 1. Join the Apple Developer Program ($99/year)
- Go to https://developer.apple.com/programs/enroll and sign in with your Apple ID
  (or use the **Apple Developer** app on your iPhone).
- Approval can take up to 48 hours. You'll get an email.

## 2. Register the app's two IDs
At https://developer.apple.com/account/resources/identifiers click **+** →
**App IDs** → **App** → Continue, and create:

| Description | Bundle ID (choose "Explicit") |
|---|---|
| Scheduler | `com.kadencrutchfield.scheduler` |
| Scheduler Messages | `com.kadencrutchfield.scheduler.messages` |

No capabilities need to be checked.

## 3. Create the app in App Store Connect
At https://appstoreconnect.apple.com → **Apps** → **+** → **New App**:
- Platform: iOS
- Name: anything not already on the App Store (e.g. "Scheduler – Find a Time")
- Bundle ID: `com.kadencrutchfield.scheduler`
- SKU: `scheduler`

## 4. Make an API key (lets GitHub upload for you)
App Store Connect → **Users and Access** → **Integrations** → **App Store Connect API**
→ **Team Keys** → **+**. Name it "GitHub", Access: **Admin**.
- Download the `.p8` file. **You can only download it once.**
- Write down the **Key ID** (next to the key) and the **Issuer ID** (at the top of the page).

Your **Team ID** is at https://developer.apple.com/account under *Membership details*.

## 5. Give GitHub the keys
On GitHub: this repo → **Settings** → **Secrets and variables** → **Actions** →
**New repository secret**. Add these four:

| Name | Value |
|---|---|
| `APPLE_TEAM_ID` | your Team ID (10 characters) |
| `ASC_KEY_ID` | the Key ID |
| `ASC_ISSUER_ID` | the Issuer ID |
| `ASC_KEY_P8` | open the `.p8` file in a text editor and paste **everything**, including the `-----BEGIN PRIVATE KEY-----` and `-----END PRIVATE KEY-----` lines |

## 6. Build and upload
GitHub → **Actions** → **TestFlight** → **Run workflow**. It takes about 10 minutes.
Apple then "processes" the build for 5–30 minutes.

## 7. Install it on your phone
- App Store Connect → your app → **TestFlight** → **Internal Testing** → **+** to make a group → add yourself.
- Install the **TestFlight** app from the App Store on your iPhone and sign in with the same Apple ID.
- Install Scheduler from TestFlight.
- Open Messages, pick a chat, tap **+** → **More** → **Scheduler**.

## 8. Let friends try it
In TestFlight → **External Testing** → create a group → turn on **Public Link** and text
that link to friends. The first build for outside testers goes through a quick Apple review
(usually under a day). You'll need to fill in a short "What to Test" note and contact email.

To ship a new version later, just run the TestFlight workflow again.
