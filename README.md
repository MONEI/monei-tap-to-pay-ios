# MONEI Tap to Pay SDK for iOS

Accept contactless card payments with Tap to Pay on iPhone inside your own iOS app. MONEI processes the payments.

This repository contains the Swift package, the release binaries and an example app (`Example/`).

## Requirements

- iOS 18.5 or later, on an iPhone XS or newer. `TapToPay.isSupported` is `false` on other devices.
- Xcode 26.6 or newer.
- The Tap to Pay on iPhone entitlement from Apple, for each app that takes payments. Request it with Apple's [entitlement request form](https://developer.apple.com/contact/request/tap-to-pay-on-iphone/):
  1. Request the development entitlement for your team. You need it before you can test on a device.
  2. Build and test your payment flow with it.
  3. Request the publishing entitlement. Apple asks for screenshots or a video of your payment flow.

  App extensions that never take payments (for example a widget) do not need the entitlement.
- In your app target:
  - Add the entitlement key `com.apple.developer.proximity-reader.payment.acceptance` with the value `true` to the `.entitlements` file.
  - Add `NSLocationWhenInUseUsageDescription` to `Info.plist`. The SDK needs the location of the device to accept payments.
  - Add your Apple Team ID to `Info.plist` with the key `PRODUCT_TEAM_IDENTIFIER`. The payment engine uses it to attest your app. Without it, the reader setup fails, and `prepare` and `acceptPayment` throw `paymentFailed`.
    1. In the build settings of your app target, add a user-defined setting `PRODUCT_TEAM_IDENTIFIER`. Set it to your Apple Team ID (10 characters, in your Apple Developer account under **Membership details**). Use the team that signs the app.
    2. Add this entry to `Info.plist`:

       ```xml
       <key>PRODUCT_TEAM_IDENTIFIER</key>
       <string>$(PRODUCT_TEAM_IDENTIFIER)</string>
       ```

    If Xcode generates the `Info.plist` of your target (no `Info.plist` file), add an `Info.plist` file with only this entry and set **Info.plist File** (`INFOPLIST_FILE`) to its path. Xcode merges the file with the generated keys. The `INFOPLIST_KEY_` build settings cannot add this key.

    The value must be in the `Info.plist` of the built app. To check, open the `.app` and look at its `Info.plist`.
- A MONEI account and its API key. A test mode API key gives sandbox tokens.
- App Store privacy details. Declare these data types in App Store Connect, all for app functionality and not for tracking:
  - Coarse location, not linked to the user (this SDK).
  - Precise location, not linked to the user (the payment engine in this package).
  - Device ID, linked to the user (the payment engine in this package).

Use the name "Tap to Pay on iPhone" in your UI, as the Apple Human Interface Guidelines require.

## Install

The package is public. Swift Package Manager downloads the binaries from the release of each version. No GitHub account or token is necessary, also not in CI.

In Xcode, select **File > Add Package Dependencies**, enter the URL below, set the dependency rule to **Exact Version** `0.2.0`, and add the `MoneiTapToPay` product to your app target:

```
https://github.com/MONEI/monei-tap-to-pay-ios
```

In `Package.swift`:

```swift
dependencies: [
  .package(url: "https://github.com/MONEI/monei-tap-to-pay-ios", exact: "0.3.0")
],
targets: [
  .target(name: "YourApp", dependencies: [
    .product(name: "MoneiTapToPay", package: "monei-tap-to-pay-ios")
  ])
]
```

Use `exact:` for 0.x versions. From 1.0.0, use `from:`.

Use `0.1.1` or later. Earlier versions download their binaries through the GitHub API, which needs a GitHub token.

Until 2026-10-01 this repo was `MONEI/monei-tap-to-pay-ios-spm`. If you added the package with that URL, remove it and add it again with the URL above: the package identity changed.

## Backend: get a token

The app needs a POS token for each payment session. Your server gets the token from the MONEI API. The API key stays on your server. Never put the API key in the app.

```sh
curl -X POST https://api.monei.com/v1/pos/auth-token \
  -H "Authorization: $MONEI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"storeId": "<MONEI store ID>"}'
```

Response:

```json
{ "token": "<jwt>" }
```

Send only the value of the `token` field to the app. Do not send the full JSON body. The SDK cannot use it.

Optional body fields:

| Field | Value |
|---|---|
| `storeId` | The MONEI store ID of the physical store of the device. MONEI records the payments under this store. The store must belong to the account of the API key. If not, payments fail with "Store not found". |
| `pointOfSaleId` | The ID of a Point of Sale that you created in MONEI. Never use a device identifier here. If you send it, the store comes from the Point of Sale. |

Rules:

- **One token for each device.** Cache the token for each device.
- **Renew before expiry.** A token is valid for 24 hours. Get a new token before it expires. Then call `prepare` again with the new token.
- **Several MONEI accounts.** If you have more than one MONEI account (for example, separate legal entities), each device uses the API key of the account that its store belongs to. Use one account on each device. MONEI has not tested a switch to another account on one device yet.
- **Test and live.** A test mode API key gives a sandbox token. A live API key gives a live token. Do not mix test and live tokens on one device.

API reference: https://docs.monei.com/apis/rest/pos-auth-token-create/

## App: accept a payment

The API is `@MainActor`. Call it from the main actor, for example from a SwiftUI view.

```swift
import MoneiTapToPay

// On launch, and again after each token renewal.
func startTapToPay() async {
  guard TapToPay.isSupported else { return } // Hide Tap to Pay on iPhone in your UI.
  do {
    let token = try await myServer.fetchPosToken() // The "token" field only.
    try await TapToPay.prepare(token: token)
  } catch {
    // See "Errors".
  }
}

// When the customer pays.
func pay(amountInCents: Int, orderId: String) async {
  do {
    let result = try await TapToPay.acceptPayment(
      amount: amountInCents,
      orderId: orderId,
      callbackUrl: URL(string: "https://example.com/monei/webhook"))
    switch result.status {
    case .approved: showApproved(result)
    case .declined: showDeclined(result)
    @unknown default: showPending(orderId)
    }
  } catch TapToPayError.outcomeUnknown(let orderId) {
    // Do not retry. Check this orderId in MONEI (see "Errors").
    showPending(orderId)
  } catch {
    // See "Errors".
  }
}
```

### Public API

| Symbol | Description |
|---|---|
| `TapToPay.isSupported: Bool` | `true` when the device supports Tap to Pay on iPhone. |
| `TapToPay.prepare(token: String) async throws` | Stores the token and prepares the reader in the background. It does not show Apple's terms. It asks for location permission if the user did not answer yet. Call it on launch and after each token renewal. |
| `TapToPay.acceptPayment(amount: Int, orderId: String, callbackUrl: URL?) async throws -> PaymentResult` | Takes one card payment. `amount` is in euro cents and must be more than 0. `orderId` is your own reference and must not be empty. |
| `TapToPay.presentEducation(from: UIViewController) async throws` | Shows Apple's screens that teach how to tap a card. |
| `TapToPay.isAccountLinked() async throws -> Bool` | From 0.4.0. `true` when the account of the stored token accepted Apple's Tap to Pay on iPhone terms on this device. It never shows the terms. It prepares the reader as `prepare` does. |
| `TapToPay.linkAccount() async throws` | From 0.4.0. Shows Apple's terms if the account did not accept them yet, then prepares the reader. Call it only from a user action. |
| `TapToPay.readerState: ReaderState` | From 0.4.0. The reader state now: `notReady`, `preparing(progress:)` or `ready`. |
| `TapToPay.readerStates() -> AsyncStream<ReaderState>` | From 0.4.0. The reader state now, then each change. Each call gets its own stream. |
| `PaymentResult` | `paymentId` (MONEI payment ID), `status` (`.approved` or `.declined`), `cardBrand` (the card network name in lowercase, for example `visa` or `amex`; `unknown` for a network the SDK does not know; or `nil`), `last4` (or `nil`), `orderId`, `amount` (in cents), `currency` (ISO 4217, for example `EUR`), `statusCode` and `statusMessage` (the MONEI status code and its text, for example `E000`; a declined result also has the reason, for example insufficient funds; or `nil`), `authorizationCode` (approved results only; or `nil`), `cardType` (`credit`, `debit` or `prepaid`; or `nil`), `cardCountry` (ISO 3166-1 alpha-2, for example `ES`; or `nil`). Only `status` tells you if the payment is approved. Use the other fields to show the result. |

### Payment flow

1. Call `prepare` on launch. The token stays in memory only, so call `prepare` again after each launch.
2. Call `acceptPayment` with your own `orderId`. Use a new, non-empty `orderId` for each order. MONEI stores it with the payment, and you use it to reconcile.
3. The SDK needs a location fix to prepare the reader. The first call after launch that prepares the reader (`prepare`, `acceptPayment`, `isAccountLinked` or `linkAccount`) waits up to 15 seconds for it.
4. If the account did not accept Apple's Tap to Pay on iPhone terms yet, `acceptPayment` shows them first. Apple asks you to offer the terms before checkout too. See [Accept Apple's terms before checkout](#accept-apples-terms-before-checkout).
5. Apple shows the tap screen. The customer taps the card.
6. `acceptPayment` returns a `PaymentResult` or throws a `TapToPayError`.

The SDK prepares the reader again when the app comes back to the foreground. You do not need to do this.

The SDK never retries a payment.

### Trusted result: the webhook

Always pass `callbackUrl`. MONEI sends a signed webhook to this URL with the payment result. The signed webhook is the only trusted payment result. Verify its signature on your server. Use the app result for the UI only.

### Education

Call `presentEducation(from:)` to show Apple's education screens: after the user accepts Apple's terms, and from your settings or help menu.

### Accept Apple's terms before checkout

From 0.4.0. Apple asks that the merchant can accept the Tap to Pay on iPhone terms before the first customer, for example at the end of your onboarding and from your settings. Use `isAccountLinked()` to show the state and `linkAccount()` to show the terms.

```swift
// Settings: read the state from Apple each time. Do not store it.
func refreshTapToPayStatus() async {
  enabled = (try? await TapToPay.isAccountLinked()) ?? false
}

// The button that enables Tap to Pay on iPhone. Show it only to a user who can accept the terms
// for the business. Show other users a message to contact an administrator.
func enableTapToPay(from viewController: UIViewController) async {
  do {
    try await TapToPay.linkAccount() // Shows Apple's terms if they were not accepted yet.
    enabled = true
    try await TapToPay.presentEducation(from: viewController)
  } catch TapToPayError.termsDeclined {
    // The user did not accept the terms. Keep the button.
  } catch {
    // See "Errors".
  }
}
```

- Call `prepare` first. Both calls use the stored token.
- `isAccountLinked()` never shows the terms. It also returns `false` when the check fails. This is safe: `linkAccount()` shows no terms to an account that accepted them.
- After the user accepts the terms, `linkAccount()` prepares the reader. This can take some seconds. Show the [reader state](#show-the-reader-state) until it returns.
- While either call runs, `acceptPayment` throws `busy`. Do not start them when the user is about to pay. If the user taps the Tap to Pay on iPhone button while a check runs, wait for the check to end, then call `acceptPayment`. Do not grey out the button: Apple does not allow it.
- Keep the Tap to Pay on iPhone button in checkout. If the terms were not accepted, `acceptPayment` shows them.
- Only a user who can accept the terms for the business must see Apple's terms. `acceptPayment` cannot check this. For a user who cannot accept them, call `isAccountLinked()` when the checkout screen opens. If it returns `false`, the Tap to Pay on iPhone button shows a message to contact an administrator and does not call `acceptPayment`.
- For the button text, use Apple's approved wording in the [Tap to Pay on iPhone marketing guidelines](https://developer.apple.com/tap-to-pay/marketing-guidelines/).

### Show the reader state

From 0.4.0. Apple asks for a progress indicator while the device configures Tap to Pay on iPhone, and for an initializing view when the user starts a payment before the reader is ready. Use `readerStates()`.

```swift
struct TapToPayStateView: View {
  @State private var state = TapToPay.readerState

  var body: some View {
    Group {
      switch state {
      case .ready: Text("Ready")
      case .preparing(let progress?):
        ProgressView("Preparing", value: Double(progress), total: 100)
      case .preparing: ProgressView("Preparing")
      case .notReady: Text("Not ready")
      @unknown default: EmptyView()
      }
    }
    .task { for await next in TapToPay.readerStates() { state = next } }
  }
}
```

| State | Meaning |
|---|---|
| `notReady` | The reader is not set up: no `prepare` yet, the account did not accept Apple's terms, the last setup failed, or MONEI blocked this SDK version. The next call that needs the reader sets it up or throws. |
| `preparing(progress:)` | The reader is being set up, or the SDK sets it up again at the next call, for example after the app comes back to the foreground. `progress` is 0 to 100 while the device downloads its configuration. Show a determinate indicator. When `progress` is `nil`, show an indeterminate indicator. |
| `ready` | The reader is ready. `acceptPayment` opens Apple's screen at once. |

- Each call gets its own stream. A stream ends when its task is cancelled or the stream is released, as with a SwiftUI `.task`. A `break` out of the loop alone does not end a stream that you still hold.
- At checkout, call `acceptPayment` when the user taps the Tap to Pay on iPhone button. While the state is not `ready`, show an initializing view, for example "Tap to Pay on iPhone will be ready soon". Apple's screen opens when the reader is ready.
- After the card read, Apple's screen closes. Show a processing view until `acceptPayment` returns.

## Apple requirements

Before Apple gives the publishing entitlement, it reviews your app against its Tap to Pay on iPhone requirements. Apple sends the requirement checklist with the entitlement process. The table gives our summary of each item and how you meet it with this SDK. Apple's checklist is the reference. Also read Apple's [Human Interface Guidelines for Tap to Pay on iPhone](https://developer.apple.com/design/human-interface-guidelines/tap-to-pay-on-iphone) and the [marketing guidelines](https://developer.apple.com/tap-to-pay/marketing-guidelines/).

| Item | Summary | How you meet it |
|---|---|---|
| 1.1 | Support Tap to Pay on iPhone on all supported iPhone models. | `TapToPay.isSupported`. Hide Tap to Pay on iPhone when it is `false`. |
| 1.2, 1.3 | If Tap to Pay on iPhone is your main payment method: a deployment target and device capabilities that support it. | The SDK needs iOS 18.5. Set your deployment target to iOS 18.5 or later. Set the device capabilities in your app. |
| 1.4 | Tell the user to update iOS when the iOS version does not support Tap to Pay on iPhone. | The SDK needs iOS 18.5, so your app does not run on the old iOS versions that Apple names. If Apple reports the iOS version as not supported, the calls throw `osUpdateRequired` (from 0.4.0). Tell the user to update iOS. |
| 1.5 | Prepare Tap to Pay on iPhone at launch and when the app comes to the foreground. | Call `prepare` at launch. The SDK prepares the reader again in the foreground. |
| 1.6 | Get the terms status from Apple. Do not store it in your app. | `isAccountLinked()` (from 0.4.0). |
| 1.7 to 1.9 | Face ID or Touch ID login, Apple's Human Interface Guidelines and marketing guidelines. | Your app. |
| 2.1 to 2.3 | A digital onboarding in the app that a new merchant can complete quickly on iPhone. | Your app and the MONEI account onboarding. |
| 3.1 to 3.4 | Communication about Tap to Pay on iPhone: visible, to all eligible users, and at the end of the onboarding. | Your app, with Apple's marketing assets. |
| 3.5 to 3.7 | A clear action to accept the terms, also outside checkout (for example in settings), and in checkout or before it. | `linkAccount()` from onboarding and settings (from 0.4.0). In checkout, `acceptPayment` shows the terms if they were not accepted. |
| 3.8, 3.8.1 | Only an administrator accepts the terms. Other users see a message to contact an administrator. | Your app decides who may call `linkAccount()`. For other users, use `isAccountLinked()` and your message. See [Accept Apple's terms before checkout](#accept-apples-terms-before-checkout). |
| 3.8.2 | Enterprise apps: accept the terms outside the app. | Contact MONEI. |
| 3.9 | A screen that invites the merchant to try Tap to Pay on iPhone after the terms and the education. | Your app. |
| 3.9.1 | A configuration progress indicator. | `readerStates()`, `preparing(progress:)` (from 0.4.0). |
| 4.1 to 4.3 | Merchant education with Apple's content after the terms are accepted, and from settings or help. | `presentEducation(from:)` after `linkAccount()`, and from your settings or help. It shows Apple's current, localized content. |
| 4.4 to 4.8 | Education content: cards, digital wallets, PIN entry and fallback where the region needs them; Apple's toolkit outside the app. | Apple's content from `presentEducation` covers the in-app part. |
| 5.1 to 5.5 | A visible Tap to Pay on iPhone button in checkout, at the top, never disabled, with Apple's text and symbol. | Your app. |
| 5.6 | Apple's screen opens within one second. | Call `prepare` at launch. The SDK keeps the reader ready in the foreground. |
| 5.7 | An initializing view when the reader is not ready yet. | Show it while `readerState` is not `ready` (from 0.4.0). See [Show the reader state](#show-the-reader-state). |
| 5.8 | A processing view after the card read. | Show your processing view while `acceptPayment` runs. Apple's screen covers it during the card read. |
| 5.9 | A clear result: approved, declined or timed out. | `PaymentResult.status` and `TapToPayError`. For `outcomeUnknown`, show a pending state. |
| 5.10 | A digital receipt for the customer. | Send it with the MONEI API ([send payment receipt](https://docs.monei.com/apis/rest/payments-send-receipt/)) and the `paymentId`, or your own receipt. |
| 5.11 | Regional requirements. | Contact MONEI. |

### Review videos

Apple asks for three screen recordings with the entitlement request:

1. **Onboarding.** A new user signs up (with identity checks, if you have them). Then show how your app introduces Tap to Pay on iPhone after the merchant account is approved.
2. **Enabling and education.** An existing user learns that Tap to Pay on iPhone is available and accepts the terms. Show each path to the terms, for example from settings and from checkout. Show the education after the terms, where the user finds it later, and the progress indicator if the configuration is not complete.
3. **Checkout.** Enter an amount, show the payment options and the Tap to Pay on iPhone button, the initializing view if Apple's screen takes more than a moment to open, and a successful payment. Show PIN entry and the fallback payment method where your region needs them. Record this video with a second device: a screen recording does not show Apple's Tap to Pay on iPhone screens.

### Switch statements

The SDK uses library evolution. Its public enums are not frozen. A `switch` over `PaymentResult.Status`, `TapToPayError` or `TapToPayErrorCode` needs an `@unknown default` case. Without it, your app does not compile.

## Errors

All calls throw `TapToPayError`.

| Error | Thrown by | Meaning | What to do |
|---|---|---|---|
| `notSupported` | all calls | The device or iOS version does not support Tap to Pay on iPhone. | Hide Tap to Pay on iPhone. |
| `locationDenied` | `prepare`, `acceptPayment`, `isAccountLinked`, `linkAccount` | The user did not allow location access, or `Info.plist` has no `NSLocationWhenInUseUsageDescription`. | If the user did not allow access: tell the user to allow location access in Settings, then try again. If the key is missing: add it to `Info.plist` and release a corrected app. |
| `termsDeclined` | `acceptPayment`, `linkAccount` | The user did not accept Apple's terms, or linking failed. | Tell the user that the terms are necessary. The next `linkAccount` or `acceptPayment` shows the terms again. |
| `invalidArgument` | `acceptPayment` | `amount` is 0 or less, or `orderId` is empty. | Correct the value. |
| `tokenExpired` | `prepare`, `acceptPayment`, `isAccountLinked`, `linkAccount` | The token expired. | Get a new token from your server. Call `prepare`. Then try again. |
| `invalidToken` | `prepare` | The SDK cannot read the token. | Send only the `token` field. Get a new token and call `prepare`. Until then, the other calls throw `notPrepared`. |
| `notPrepared` | `acceptPayment`, `isAccountLinked`, `linkAccount` | No valid token is stored. | Call `prepare` first. |
| `busy` | `acceptPayment`, `isAccountLinked`, `linkAccount` | A payment, a terms check (`isAccountLinked`) or a link (`linkAccount`) is in progress. | Wait until it ends. Do not start a second payment while one runs. If a terms check runs, wait for it to end, then call `acceptPayment`. |
| `cancelled` | `acceptPayment` | The user cancelled on Apple's screen. No payment occurred. | Start a new payment when the customer is ready. |
| `sdkUpgradeRequired` | `prepare`, `acceptPayment`, `isAccountLinked`, `linkAccount` | MONEI blocked this SDK version. All these calls fail with this error. | Update to a newer SDK version and release your app. |
| `osUpdateRequired` | `prepare`, `acceptPayment`, `isAccountLinked`, `linkAccount` | From 0.4.0. Apple reports that this iOS version does not support Tap to Pay on iPhone. | Tell the user to update iOS to the latest version. Then try again. |
| `outcomeUnknown(orderId:)` | `acceptPayment` | The SDK cannot tell if the payment reached MONEI. The card can be charged. Causes: a connection or server error at any step of the payment, a card read error, a PIN entry error, a lost reader session during the payment, a reply that is not a clear approval or a clear decline (this can also occur when the card is declined), or a cancelled task. Some of these occur before the card is charged, but the SDK cannot tell which. | **Do not retry, and do not charge again with a new `orderId`.** Show a pending state. Wait for the signed webhook for this `orderId`, or find the `orderId` in the MONEI Dashboard ([Payments](https://docs.monei.com/manage-account/transaction-history/), filter by order ID) or with the GraphQL API [`charges`](https://docs.monei.com/apis/graphql/operations/queries/charges/) query (`filter.orderId`). If no payment shows, this does not prove that the card was not charged. Contact MONEI support with the `orderId` before you charge the customer again. |
| `paymentFailed(code:)` | all calls | The payment or setup failed. See the codes below. | See the codes below. |

`TapToPayErrorCode` values:

| Code | Meaning | What to do |
|---|---|---|
| `cardDeclined` | The card was declined during the read. No payment occurred. | Ask for a different card. |
| `readerNotReady` | The reader session was not ready or expired. | Try again. The SDK prepares the reader again on the next call. |
| `locationTimeout` | The device did not get a location in 15 seconds. | Make sure that Location Services are on. Then try again. |
| `readerSetupFailed(reason:)` | `prepare`, `acceptPayment`, `isAccountLinked` or `linkAccount` could not set up the reader before a payment started. No payment occurred. `reason` gives the step and an error code, for example `CONFIGURE_ERROR reader.sdk:ATT019`. It is for your logs and MONEI support. Do not parse it. | Try again. If the error continues, send `reason` to MONEI. |
| `unknown` | The payment did not start. No payment occurred. | Try again. If the error continues, contact MONEI. |

A `PaymentResult` with status `.declined` is not an error. The card was read and the issuer declined the payment. The payment is in MONEI with its `paymentId`.

## Versioning

The SDK uses semantic versioning (`MAJOR.MINOR.PATCH`).

- **Patch:** bug fixes. No change to the public API or to error semantics.
- **Minor:** the same public API with a new version of the internal payment engine, or new API that does not break your code.
- **Major:** a change in error semantics, or a change that breaks your code.
- **0.x versions:** until 1.0.0, a minor version (0.2.0) can change the public API. Use `exact:` and read the notes before you update.
- **Prereleases** (`-beta.N`) are for testing only. Do not ship them to production.

Releases from `0.1.0-beta.4` have a signed `MoneiTapToPay` binary (team `72J3PXJJ4K`). `0.1.0-beta.3` is not signed.

| SDK version | iOS minimum | Built with | Notes |
|---|---|---|---|
| `0.3.0` | 18.5 | Xcode 26.6 (Swift 6.3.3) | New `TapToPayErrorCode.readerSetupFailed(reason:)`: a reader setup failure gives the step and an error code, not `unknown`. Code that matches `.paymentFailed(code: .unknown)` does not catch it. A `switch` with no `@unknown default` does not compile. |
| `0.2.0` | 18.5 | Xcode 26.6 (Swift 6.3.3) | `PaymentResult` has new fields: `amount`, `currency`, `statusCode`, `statusMessage`, `authorizationCode`, `cardType`, `cardCountry`. A declined result shows the reason without a call to MONEI. No change to existing fields. |
| `0.1.1` | 18.5 | Xcode 26.6 (Swift 6.3.3) | Install without a GitHub token: public download URLs. Same SDK code as `0.1.0`. |
| `0.1.0` | 18.5 | Xcode 26.6 (Swift 6.3.3) | First release. Signed. Same code as `0.1.0-beta.5`. |
| `0.1.0-beta.5` | 18.5 | Xcode 26.6 (Swift 6.3.3) | Prerelease for internal testing. Signed. First release of the repo under its new name. |
| `0.1.0-beta.4` | 18.5 | Xcode 26.6 (Swift 6.3.3) | Prerelease for internal testing. Signed. |
| `0.1.0-beta.3` | 18.5 | Xcode 27.0 (Swift 6.4) | Prerelease for internal testing. Not signed. |

Use the same Xcode version as "Built with", or a newer one.

## Example app

`Example/TapToPayExample.xcodeproj` is a SwiftUI app that uses this package. It has a token field, an amount, an order ID, a pay button, education and a result view. Set your team and bundle ID, then run it on a supported iPhone. The example sets `PRODUCT_TEAM_IDENTIFIER` to `$(DEVELOPMENT_TEAM)`, so the `Info.plist` key gets the team that you set.
