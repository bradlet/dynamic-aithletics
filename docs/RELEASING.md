# Releasing to the App Store

A step-by-step guide for publishing Dynamic AIthletics to the Apple App Store. This guide assumes you have never submitted an app for review before.

## Prerequisites

Before you begin, you will need:

- A Mac running macOS 14+ with Xcode 15+ installed
- An Apple ID
- An iPhone or iPad running iOS 17+ (for physical device testing, recommended before submission)
- $99 USD/year for the Apple Developer Program membership

## Step 1: Enroll in the Apple Developer Program

You need a paid Apple Developer Program membership to distribute apps on the App Store.

1. Go to [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/)
2. Sign in with your Apple ID (or create one)
3. Follow the enrollment steps — you'll need to verify your identity
4. Pay the $99/year fee
5. Wait for enrollment approval (usually within 48 hours, sometimes minutes)

Once approved, you'll have access to [App Store Connect](https://appstoreconnect.apple.com) and the full developer portal.

**Reference:** [Apple Developer Program enrollment documentation](https://developer.apple.com/support/enrollment/)

## Step 2: Register a Bundle Identifier

The bundle identifier uniquely identifies your app across all of Apple's systems. Dynamic AIthletics needs one registered in the developer portal.

1. Go to [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. Click the **+** button to register a new identifier
3. Select **App IDs**, then **App**
4. Fill in:
   - **Description:** Dynamic AIthletics
   - **Bundle ID:** Select "Explicit" and enter your bundle ID (e.g. `com.bradleythompson.DynamicAIthletics`). This must match the bundle identifier in Xcode.
5. Under **Capabilities**, enable:
   - **CloudKit** (required — the app uses CloudKit sync)
   - **Push Notifications** (required by CloudKit for background sync)
6. Click **Continue**, then **Register**

**Important:** Open the Xcode project and verify that the bundle identifier in **Signing & Capabilities** matches what you just registered. Go to the project navigator > select the "Dynamic AIthletics" target > **General** tab > **Bundle Identifier**.

## Step 3: Register a CloudKit Container

Dynamic AIthletics syncs data via CloudKit. The container must be registered.

1. Go to [developer.apple.com/account/resources/identifiers](https://developer.apple.com/account/resources/identifiers/list)
2. In the dropdown at the top-right, switch from "App IDs" to **iCloud Containers**
3. Click **+** to register a new container
4. Enter an identifier, e.g. `iCloud.com.bradleythompson.DynamicAIthletics`
5. Click **Continue**, then **Register**
6. Back in Xcode, open **Signing & Capabilities** for the app target
7. Under the **iCloud** capability, check **CloudKit** and select the container you just created
8. Verify that `Dynamic_AIthletics.entitlements` contains the correct container ID under `com.apple.developer.icloud-container-identifiers`

**Reference:** [CloudKit Quick Start](https://developer.apple.com/documentation/cloudkit/enabling_cloudkit_in_your_app)

## Step 4: Configure Signing in Xcode

Code signing proves the app came from you. Xcode can manage this automatically.

1. Open the project in Xcode
2. Select the **Dynamic AIthletics** target
3. Go to the **Signing & Capabilities** tab
4. Check **Automatically manage signing**
5. Select your **Team** from the dropdown (this is your Apple Developer account)
6. Xcode will create the necessary signing certificate and provisioning profile

If you see errors about provisioning profiles, try:
- Xcode menu > **Settings** > **Accounts** > make sure your Apple ID is added and your team is listed
- Click **Download Manual Profiles** if automatic management fails

**Reference:** [Xcode code signing documentation](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## Step 5: Create the App in App Store Connect

App Store Connect is Apple's web portal for managing your app's listing, pricing, and review status.

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com)
2. Click **My Apps** (or **Apps** in the sidebar)
3. Click the **+** button > **New App**
4. Fill in:
   - **Platforms:** iOS
   - **Name:** Dynamic AIthletics (this is what users see on the App Store)
   - **Primary Language:** English (U.S.) (or your preferred language)
   - **Bundle ID:** Select the bundle ID you registered in Step 2
   - **SKU:** A unique internal identifier (e.g. `dynamic-aithletics-001`). Not visible to users.
   - **User Access:** Full Access (unless you have team members to restrict)
5. Click **Create**

**Reference:** [App Store Connect help — create an app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app)

## Step 6: Prepare the App Store Listing

Before submitting for review, you need to fill out the app's metadata. From your app's page in App Store Connect:

### App Information (sidebar)
- **Category:** Health & Fitness
- **Content Rights:** Confirm you own or have rights to all content

### Pricing and Availability (sidebar)
- Set the price (Free, or choose a price tier)
- Select the countries/regions to distribute in

### App Privacy (sidebar)
Apple requires a privacy nutrition label. Dynamic AIthletics collects:
- **Health & Fitness data** (workout distance, duration) — linked to user via CloudKit
- **Identifiers** (CloudKit record IDs) — used for syncing

Fill in the privacy questionnaire honestly based on what data the app accesses.

**Reference:** [App privacy details on the App Store](https://developer.apple.com/app-store/app-privacy-details/)

### Version Information (main area)
For your first version (1.0), you'll need:

| Field | What to provide |
|-------|----------------|
| **Screenshots** | At least one set for iPhone 6.7" display (iPhone 15/16 Pro Max). Capture from the simulator: **Simulator menu > File > Save Screen**. You need 2-10 screenshots. Show the weekly calendar, history tab, and recording flow. |
| **App Previews** (optional) | Short video demos. Not required for initial submission. |
| **Description** | 1-2 paragraphs describing the app. Visible on the App Store listing page. |
| **Keywords** | Comma-separated, max 100 characters total. E.g. `running,exercise,training,workout,mileage,fitness,tracking` |
| **Support URL** | Required. Can be a GitHub repo URL, a simple landing page, or an email contact page. |
| **Marketing URL** (optional) | Your website or landing page. |
| **Version** | `1.0` |
| **Copyright** | `2026 Bradley Thompson` |

**Screenshot sizes reference:** [App Store Connect screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications)

## Step 7: Build and Archive the App

An "archive" is Xcode's term for a release build packaged for distribution.

1. In Xcode, set the build target to **Any iOS Device (arm64)** (not a simulator)
2. Set the version and build number:
   - Select the project target > **General** tab
   - **Version:** `1.0.0`
   - **Build:** `1` (increment this for each upload; Apple requires unique build numbers)
3. **Product** menu > **Archive**
4. Xcode will compile a release build. When it finishes, the **Organizer** window opens automatically showing your archive.

If the archive fails:
- Make sure you selected a physical device target, not a simulator
- Verify signing is configured correctly (Step 4)
- Check for any build errors in the issue navigator

## Step 8: Upload to App Store Connect

From the Xcode Organizer (opened automatically after archiving, or via **Window > Organizer**):

1. Select your archive
2. Click **Distribute App**
3. Select **App Store Connect** as the distribution method
4. Select **Upload** (not Export)
5. Leave the default options:
   - Include bitcode: No (deprecated in Xcode 16+)
   - Upload symbols: Yes
   - Manage version and build number: Yes
6. Click **Upload**
7. Wait for the upload to complete (may take several minutes)

After uploading, the build goes through Apple's **automated processing** (5-30 minutes). You'll receive an email when it's ready. If there are issues (missing icons, invalid entitlements), you'll get an email detailing what to fix.

You can also upload using the `xcodebuild` CLI:

```bash
# Archive
xcodebuild archive \
  -scheme "Dynamic AIthletics" \
  -archivePath ./build/DynamicAIthletics.xcarchive \
  -destination 'generic/platform=iOS'

# Export for App Store upload
xcodebuild -exportArchive \
  -archivePath ./build/DynamicAIthletics.xcarchive \
  -exportPath ./build/export \
  -exportOptionsPlist ExportOptions.plist

# Upload (requires an app-specific password — see below)
xcrun altool --upload-app \
  -f ./build/export/Dynamic\ AIthletics.ipa \
  -u your@apple.id \
  -p @keychain:AC_PASSWORD
```

**Reference:** [Distributing your app for beta testing and releases](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases)

## Step 9: Submit for App Review

Once the build finishes processing in App Store Connect:

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) > **My Apps** > **Dynamic AIthletics**
2. Under the version (1.0), scroll to the **Build** section
3. Click **+** and select the build you uploaded
4. Fill in the **App Review Information** section:
   - **Contact info:** Your name, email, phone number (for the review team to reach you — not public)
   - **Notes:** Optional notes for the reviewer, e.g. "This is an exercise tracking app. No login is required — all data is stored locally and synced via CloudKit."
   - **Sign-in required:** No (the app doesn't have authentication)
5. Review all sections — App Store Connect will warn you if anything is missing
6. Click **Submit for Review**

## Step 10: Wait for Review

Apple's review process typically takes **24-48 hours**, though it can be faster (same day) or slower (up to a week for first submissions or if issues arise).

You'll receive email notifications for:
- **In Review** — a reviewer is looking at your app
- **Approved** — your app is approved and will be live on the App Store
- **Rejected** — the reviewer found issues (see below)

### If your app is rejected

Don't panic — rejections are common, especially for first submissions. Apple will provide a specific reason in the **Resolution Center** in App Store Connect. Common reasons:

| Rejection reason | How to fix |
|-----------------|------------|
| **Guideline 4.2 — Minimum functionality** | Apple may feel the app doesn't offer enough features. Add more polish or features and resubmit. |
| **Guideline 2.1 — Crashes/bugs** | Test thoroughly on a physical device before resubmitting. |
| **Guideline 5.1.1 — Privacy** | Ensure your privacy policy and App Privacy labels are accurate. |
| **Missing metadata** | Fill in all required fields in App Store Connect. |

You can reply to the reviewer in the Resolution Center to ask for clarification or explain your app's purpose, then resubmit.

**Reference:** [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)

## Step 11: Post-Release

After your app is live:

- **Monitor crashes** via Xcode Organizer > **Crashes** tab, or in App Store Connect > **Analytics**
- **Respond to user reviews** in App Store Connect > **Ratings and Reviews**
- **Submit updates** by incrementing the version number, archiving, and uploading a new build

### Updating the app

1. Bump the version in Xcode (e.g. `1.0.0` → `1.1.0`)
2. Increment the build number (e.g. `1` → `2`)
3. Archive and upload (Steps 7-8)
4. In App Store Connect, create a new version, attach the build, fill in "What's New", and submit for review

## Quick Reference Links

| Resource | URL |
|----------|-----|
| Apple Developer Program enrollment | [developer.apple.com/programs/enroll](https://developer.apple.com/programs/enroll/) |
| Apple Developer portal (certificates, IDs) | [developer.apple.com/account](https://developer.apple.com/account/) |
| App Store Connect | [appstoreconnect.apple.com](https://appstoreconnect.apple.com) |
| App Store Review Guidelines | [developer.apple.com/app-store/review/guidelines](https://developer.apple.com/app-store/review/guidelines/) |
| Human Interface Guidelines | [developer.apple.com/design/human-interface-guidelines](https://developer.apple.com/design/human-interface-guidelines/) |
| Screenshot specifications | [developer.apple.com/help/app-store-connect/reference/screenshot-specifications](https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications) |
| CloudKit setup | [developer.apple.com/documentation/cloudkit](https://developer.apple.com/documentation/cloudkit/enabling_cloudkit_in_your_app) |
| App privacy details | [developer.apple.com/app-store/app-privacy-details](https://developer.apple.com/app-store/app-privacy-details/) |
| Distributing your app | [developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases](https://developer.apple.com/documentation/xcode/distributing-your-app-for-beta-testing-and-releases) |
